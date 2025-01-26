# frozen_string_literal: true

require 'pathname'
require_relative 'utils'

module Runit
  SERVICE_SHORTCUTS = {
    'rails' => 'rails-*',
    'praefect' => 'praefect*',
    'gitaly' => '{gitaly,praefect*}',
    'db' => '{redis,redis-cluster,postgresql,postgresql-geo,clickhouse}',
    'rails-migration-dependencies' => '{redis,redis-cluster,postgresql,postgresql-geo,gitaly,praefect*,minio}',
    'workhorse' => 'khulnasoft-workhorse'
  }.freeze

  SERVICES_DIR = Pathname.new(__dir__).join('../services').expand_path
  LOG_DIR = Pathname.new(__dir__).join('../log').expand_path

  ALL_DATA_ORIENTED_SERVICE_NAMES = %w[minio openldap gitaly praefect redis redis-cluster postgresql-geo postgresql].freeze
  STOP_RETRY_COUNT = 3

  def self.start_runsvdir
    runit_installed!

    runit_config = Runit::Config.new(KDK.root)

    # To make transition easier, we merge legacy services that haven't been migrated yet
    # so that using Ruby services will always working even when partially migrated
    services = KDK::Services.enabled
    legacy_services = KDK::Services.legacy.select(&:enabled?)

    runit_config.render(services: services + legacy_services)

    # It is important that we use an absolute path with `runsvdir`: this
    # allows us to distinguish processes belonging to different KDK
    # installations on the same machine.
    args = runsvdir_base_args
    return if runsvdir_pid(args)

    dots = '.' * 395

    Process.fork do
      Dir.chdir('/')
      Process.setsid

      # Cargo-culting the use of 395 periods from omnibus-khulnasoft.
      # https://khulnasoft.com/khulnasoft-org/omnibus-khulnasoft/blob/5dfdcafa30ad6e203a04a917f180b630d5121cf6/config/templates/runit/runsvdir-start.erb#L42
      args << "log: #{dots}"

      spawn(cleaned_path_env, *args, in: '/dev/null', out: '/dev/null', err: '/dev/null')
    end
  end

  # Runit does not handle ENOTDIR from execve well, so let's try to
  # prevent that.
  # https://github.com/khulnasoft/khulnasoft-development-kit/issues/666#note_241939982
  def self.cleaned_path_env
    valid_path_entries = ENV['PATH'].split(File::PATH_SEPARATOR).select do |dir|
      File.directory?(dir)
    end

    { 'PATH' => valid_path_entries.join(File::PATH_SEPARATOR) }
  end

  def self.runsvdir_base_args
    ['runsvdir', '-P', KDK.root.join('services').to_s]
  end

  def self.runsvdir_pid(args)
    pgrep = KDK::Shellout.new(%w[pgrep runsvdir]).run
    return if pgrep.empty?

    pids = pgrep.split("\n").map { |str| Integer(str) }
    runsvdir_ps = "#{args.join(' ')} "

    pids.find do |pid|
      KDK::Shellout.new(%W[ps -o args= -p #{pid}]).run.start_with?(runsvdir_ps)
    end
  end

  def self.runit_installed!
    return if Utils.executable_exist?('runsvdir')

    abort <<~MESSAGE

      ERROR: khulnasoft-development-kit requires Runit to be installed.
      You can install Runit with:

        #{runit_instructions}

    MESSAGE
  end

  def self.runit_instructions
    if KDK::Dependencies.homebrew_available?
      'brew install runit'
    elsif KDK::Dependencies.macports_available?
      'sudo port install runit'
    elsif KDK::Dependencies.linux_apt_available?
      'sudo apt install runit'
    else
      '(no copy-paste Runit installation snippet available for your OS)'
    end
  end

  def self.start(services, quiet: false)
    services = Array(services)

    if services.empty?
      # Redis, PostgresSQL, etc should be started first.
      data_oriented_service_names.reverse_each.all? { |service_name| sv('start', [service_name], quiet: quiet) }
      services = non_data_oriented_service_names
    end

    sv('start', services, quiet: quiet)
  end

  def self.stop(quiet: false)
    # Redis, PostgresSQL, etc should be stopped last.
    stop_services(non_data_oriented_service_names, quiet: quiet)
    data_oriented_service_names.all? { |service_name| stop_services([service_name], quiet: quiet) }

    unload_runsvdir!
  end

  def self.stop_services(services, quiet: false)
    # The first stop attempt may fail; ignore its return value.
    stopped = false

    STOP_RETRY_COUNT.times do |i|
      # From http://smarden.org/runit/sv.8.html:
      #
      # down: If the service is running, send it the TERM signal, and the CONT signal. If ./run exits, start ./finish if it exists. After it stops, do not restart service.
      # force-stop: Same as down, but wait up to (default) 7 seconds for the service to become down. Then report the status, and on timeout send the service the kill command.
      #
      stopped = sv('force-stop', services, quiet: quiet)
      break if stopped

      KDK::Output.notice("Retrying stop (#{i + 1}/#{STOP_RETRY_COUNT})")
    end

    true
  end

  def self.unload_runsvdir!
    # Unload runsvdir: this is safe because we have just stopped all services.
    pid = runsvdir_pid(runsvdir_base_args)
    !Process.kill('HUP', pid).nil?
  end

  def self.sv(cmd, services, quiet: false)
    start_runsvdir
    expanded_services = expand_services(services)
    ensure_services_are_supervised(expanded_services)

    expanded_services = expanded_services.filter { |es| !es.to_s.include?('redis-cluster') } unless KDK.config.redis_cluster.enabled?
    return true if expanded_services.empty? # silent skip assuming successful

    command = ['sv', '-w', KDK.config.kdk.runit_wait_secs.to_s, cmd, *expanded_services.map(&:to_s)]

    sh = KDK::Shellout.new(command, chdir: KDK.root)
    quiet ? sh.run : sh.stream
    sh.success?
  end

  def self.ensure_services_are_supervised(services)
    services.each { |svc| wait_runsv_supervise_ok!(svc) }
  end

  def self.data_oriented_service_names
    ALL_DATA_ORIENTED_SERVICE_NAMES.select do |service_name|
      SERVICES_DIR.join(service_name).exist?
    end
  end

  def self.non_data_oriented_service_names
    all_service_names - data_oriented_service_names
  end

  def self.all_service_names
    return [] unless SERVICES_DIR.exist?

    # praefect-gitaly-* services are stopped/started automatically.
    Pathname.new(SERVICES_DIR).children.filter_map do |path|
      path.basename.to_s if path.directory? && !path.basename.to_s.start_with?('praefect-gitaly-')
    end.sort
  end

  def self.expand_services(services)
    return SERVICES_DIR.glob('*').sort if services.empty?

    services.flat_map do |svc|
      service_shortcut(svc) || SERVICES_DIR.join(svc)
    end.uniq.sort
  end

  def self.service_shortcut(svc)
    glob = SERVICE_SHORTCUTS[svc]
    return unless glob

    if glob.include?('/')
      KDK::Output.error "invalid service shortcut: #{svc} -> #{glob}"

      abort
    end

    shortcut_services = SERVICES_DIR.glob(glob)
    shortcut_services.empty? ? nil : shortcut_services
  end

  def self.wait_runsv_supervise_ok!(service_dir)
    unless service_dir.directory?
      KDK::Output.error "unknown runit service: #{service_dir}"

      abort
    end

    50.times do
      begin
        service_dir.join('supervise', 'ok').open(File::WRONLY | File::NONBLOCK).close
      rescue StandardError
        sleep 0.1
        next
      end
      return
    end

    KDK::Output.error "timeout waiting for runsv in #{service_dir}"

    abort
  end

  def self.tail(services)
    log_files_for_services = log_files(services)
    if log_files_for_services.empty?
      KDK::Output.warn(<<~MSG)
        No matching services to tail.

        To view a list of services and shortcuts, run `kdk tail --help`.
      MSG
      return true
    end

    exec('tail', '-qF', *log_files_for_services.map(&:to_s))
  end

  def self.log_files(services)
    return LOG_DIR.glob(File.join('*', 'current')) if services.empty?

    services.flat_map do |svc|
      shortcut = log_shortcut(svc)
      next shortcut if shortcut

      current_log = LOG_DIR.join(svc, 'current')
      current_log if current_log.exist?
    end.compact.uniq
  end

  def self.log_shortcut(svc)
    glob = SERVICE_SHORTCUTS[svc]
    return unless glob

    if glob.include?('/')
      KDK::Output.error "invalid service shortcut: #{svc} -> #{glob}"

      abort
    end

    shortcut_logs = LOG_DIR.glob(File.join(glob, 'current'))
    shortcut_logs unless shortcut_logs.empty?
  end

  def self.kill_processes(pids)
    pids.each do |pid|
      Process.kill('TERM', pid)
    rescue SystemCallError
    end
  end
end
