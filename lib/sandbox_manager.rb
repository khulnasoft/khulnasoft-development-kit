# frozen_string_literal: true

class SandboxManager
  def initialize(config: KDK.config)
    @config = config
  end

  def status
    return :broken unless missing_sources.empty?
    return :enabled if enabled?

    :disabled
  end

  def enable!
    raise KDK::UserInteractionRequired, "Sandbox is already enabled." if enabled?
    raise KDK::UserInteractionRequired, "The path(s) #{missing_sources} are missing. Run `kdk reset-data` to create them." if status == :broken

    with_services_stopped do
      failed = false

      sandbox_paths.map do |name, path|
        sandbox_path = sandbox_dir.join('sandbox', name.to_s)
        FileUtils.cp_r(path, sandbox_path, verbose: verbose?) unless sandbox_path.exist?

        head_path = sandbox_dir.join('head', name.to_s)
        FileUtils.rm_rf(head_path, verbose: verbose?)
        FileUtils.mv(path, head_path, verbose: verbose?)
        FileUtils.rm_rf(path, verbose: verbose?)
        FileUtils.ln_sf(sandbox_path, path, verbose: verbose?)

        # Ensure Postgres doesn't complain about permissions
        FileUtils.chmod(0o700, path)
        FileUtils.chmod(0o700, head_path)
        FileUtils.chmod(0o700, sandbox_path)
      rescue StandardError
        failed = true
        raise
      end
    ensure
      next unless failed

      sandbox_paths.map do |name, path|
        head_path = sandbox_dir.join('head', name.to_s)
        if head_path.exist? && (!File.exist?(path) || File.symlink?(path))
          FileUtils.rm_f(path) # if broken symlink
          FileUtils.mv(head_path, path, verbose: verbose?)
        end
      end
    end
    nil
  end

  def disable!
    raise KDK::UserInteractionRequired, "Sandbox is already disabled." unless enabled?

    with_services_stopped do
      sandbox_paths.map do |name, path|
        head_path = sandbox_dir.join('head', name.to_s)
        FileUtils.rm_rf(path, verbose: verbose?)
        FileUtils.mv(head_path, path, verbose: verbose?)
      end
    end

    nil
  end

  def reset!
    was_enabled = enabled?
    disable! if was_enabled
    FileUtils.rm_rf(sandbox_dir, verbose: verbose?)
    enable! if was_enabled
  end

  def enabled?
    path = config.postgresql.data_dir
    setup? && File.readlink(path).end_with?('/sandbox/postgres')
  end

  def missing_sources
    sandbox_paths.values.reject(&:exist?)
  end

  private

  attr_accessor :config

  def sandbox_dir
    config.kdk_root.join('sandbox').tap do |dir|
      FileUtils.mkdir_p(dir.join('sandbox'))
      FileUtils.mkdir_p(dir.join('head'))
    rescue Errno::EEXIST
    end
  end

  def sandbox_paths
    paths = {
      postgres: config.postgresql.data_dir,
      redis: config.redis.dir.join('dump.rdb'),
      repositories: config.repositories_root
    }
    paths[:postgres_replica] = config.postgresql.replica.data_directory if config.postgresql.replica.enabled
    paths[:postgres_replica_2] = config.postgresql.replica_2.data_directory if config.postgresql.replica_2.enabled
    paths
  end

  def with_services_stopped
    Runit.stop_services(%w[rails-migration-dependencies], quiet: true)

    res = yield

    Runit.start(%w[rails-migration-dependencies], quiet: true)

    res
  end

  def postgres_data_exist?
    config.postgresql.data_dir.exist?
  end

  def setup?
    path = config.postgresql.data_dir
    File.symlink?(path) && File.exist?(File.readlink(path))
  end

  def verbose?
    config.kdk.__debug
  end
end
