# frozen_string_literal: true

module KDK
  # KDK Commands
  module Command
    # This is a list of existing supported commands and their associated
    # implementation class
    def self.command_map
      {
        'cells' => -> { KDK::Command::Cells },
        'cleanup' => -> { KDK::Command::Cleanup },
        'clickhouse' => -> { KDK::Command::Clickhouse },
        'config' => -> { KDK::Command::Config },
        'console' => -> { KDK::Command::Console },
        'component' => -> { KDK::Command::Component },
        'debug-info' => -> { KDK::Command::Removed.new('Use `kdk report` instead.') },
        'diff-config' => -> { KDK::Command::DiffConfig },
        'doctor' => -> { KDK::Command::Doctor },
        'env' => -> { KDK::Command::Env },
        'install' => -> { KDK::Command::Install },
        'kill' => -> { KDK::Command::Kill },
        'help' => -> { KDK::Command::Help },
        '-help' => -> { KDK::Command::Help },
        '--help' => -> { KDK::Command::Help },
        '-h' => -> { KDK::Command::Help },
        nil => -> { KDK::Command::Help },
        'measure' => -> { KDK::Command::MeasureUrl },
        'measure-workflow' => -> { KDK::Command::MeasureWorkflow },
        'open' => -> { KDK::Command::Open },
        'telemetry' => -> { KDK::Command::Telemetry },
        'psql' => -> { KDK::Command::Psql },
        'psql-geo' => -> { KDK::Command::PsqlGeo },
        'predictive' => -> { KDK::Command::Predictive },
        'predictive:jest' => -> { KDK::Command::Removed.new('Use `kdk predictive --jest` instead.') },
        'predictive:rspec' => -> { KDK::Command::Removed.new('Use `kdk predictive --rspec` instead.') },
        'pristine' => -> { KDK::Command::Pristine },
        'rails' => -> { KDK::Command::Rails },
        'rake' => -> { KDK::Command::Rake },
        'reconfigure' => -> { KDK::Command::Reconfigure },
        'redis-cli' => -> { KDK::Command::RedisCli },
        'report' => -> { KDK::Command::Report },
        'reset-data' => -> { KDK::Command::ResetData },
        'reset-openbao-data' => -> { KDK::Command::ResetOpenbaoData },
        'reset-praefect-data' => -> { KDK::Command::ResetPraefectData },
        'reset-registry-data' => -> { KDK::Command::ResetRegistryData },
        'import-registry-data' => -> { KDK::Command::ImportRegistryData },
        'restart' => -> { KDK::Command::Restart },
        'sandbox' => -> { KDK::Command::Sandbox },
        'send-telemetry' => -> { KDK::Command::SendTelemetry },
        'start' => -> { KDK::Command::Start },
        'status' => -> { KDK::Command::Status },
        'stop' => -> { KDK::Command::Stop },
        'switch' => -> { KDK::Command::Switch },
        'tail' => -> { KDK::Command::Tail },
        'truncate-legacy-tables' => -> { KDK::Command::TruncateLegacyTables },
        'update' => -> { KDK::Command::Update },
        'version' => -> { KDK::Command::Version },
        '-version' => -> { KDK::Command::Version },
        '--version' => -> { KDK::Command::Version }
      }.freeze
    end

    # Entry point for gem/bin/kdk.
    #
    # It must return true/false or an exit code.
    def self.run(argv)
      name = argv.shift
      command = command_map[name]

      if command
        klass = command.call

        check_gem_version!
        validate_config! if klass.validate_config?

        if klass == ::KDK::Command::Rake
          name = "kdk:rake"
        else
          check_asdf_usage
        end

        begin
          run = -> { klass.new.run(argv) }
          result = klass.track_telemetry?(argv) ? KDK::Telemetry.with_telemetry(name, &run) : run.call
        rescue UserInteractionRequired => e
          e.print!
          exit 1
        ensure
          check_workspace_setup_complete(name)
        end

        exit result
      else
        suggestions = DidYouMean::SpellChecker.new(dictionary: ::KDK::Command::COMMANDS.keys).correct(name)
        message = ["#{name} is not a KDK command"]

        if suggestions.any?
          message << ', did you mean - '
          message << suggestions.map { |suggestion| "'kdk #{suggestion}'" }.join(' or ')
          message << '?'
        else
          message << '.'
        end

        KDK::Output.warn message.join
        KDK::Output.puts

        KDK::Output.info "See 'kdk help' for more detail."
        false
      end
    end

    def self.validate_config!
      KDK.config.validate!
      KDK::Services.enabled.each(&:validate!)
      nil
    rescue StandardError => e
      KDK::Output.error("Your KDK configuration is invalid.\n\n", e)
      KDK::Output.puts(e.message, stderr: true)
      abort('')
    end

    def self.check_gem_version!
      return if Gem::Version.new(KDK::GEM_VERSION) >= Gem::Version.new(KDK::REQUIRED_GEM_VERSION)

      KDK::Output.warn("You are running an old version of the `khulnasoft-development-kit` gem (#{KDK::GEM_VERSION})")
      KDK::Output.info("Please update your `khulnasoft-development-kit` to version #{KDK::REQUIRED_GEM_VERSION}:")
      KDK::Output.info("gem install khulnasoft-development-kit -v #{KDK::REQUIRED_GEM_VERSION}")
      KDK::Output.puts
    end

    def self.check_workspace_setup_complete(command_name = nil)
      # Set by Workspaces
      return unless ENV['KS_WORKSPACE_DOMAIN_TEMPLATE']
      return if KDK.config.__cache_dir.join('.kdk_setup_complete').exist?

      # Skip warnings for config commands as they break scripts that use
      # command substitution like $(kdk config get ...)
      return if command_name == 'config'

      KDK::Output.puts
      KDK::Output.warn('KDK setup in progress...')
      KDK::Output.puts('Run `tail -f /projects/workspace-logs/poststart-stdout.log` to watch the progress.')
    end

    def self.check_asdf_usage
      # When the user opts out of 'asdf'
      return if KDK.config.asdf.opt_out? || !Dependencies.asdf_available?

      # When the user opts out of any kind of tool management
      return if KDK.config.user_defined?('tool_version_manager', 'enabled') &&
        !KDK.config.tool_version_manager.enabled?

      KDK::Output.error <<~MSG
        You are using asdf to manage KDK dependencies. KDK dropped support for asdf on #{KDK::Output.wrap_in_color('July 31st, 2025', Output::COLOR_CODE_YELLOW)}.

        To continue using KDK, migrate to mise by running:
          `kdk rake mise:migrate`

        Migration instructions available at:
          https://khulnasoft-org.khulnasoft.io/khulnasoft-development-kit/howto/mise/#how-to-migrate
      MSG
      KDK::Telemetry.send_custom_event('asdf-error', true)
      exit 1
    end
  end
end
