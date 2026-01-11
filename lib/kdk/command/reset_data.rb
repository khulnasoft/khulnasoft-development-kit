# frozen_string_literal: true

require 'net/http'

module KDK
  module Command
    # Handles `kdk reset-data` command execution
    class ResetData < BaseCommand
      help 'Back up and create fresh Gitaly storage, PostgreSQL data and Rails upload directory'

      def run(args = [])
        raise UserInteractionRequired, 'Cannot reset data while in sandbox mode. Run `kdk sandbox disable` to disable it.' if SandboxManager.new(config: config).enabled?

        fast = args.delete('--fast')
        abort_wrong_default_branch if fast && config.khulnasoft.default_branch != 'master'

        return false unless continue?
        return false unless stop_and_backup!

        return reset_data_fast! if fast

        reset_data!
      end

      private

      def abort_wrong_default_branch
        default_branch = out.wrap_in_color(config.khulnasoft.default_branch, out::COLOR_CODE_BLUE)
        setting = out.wrap_in_color('khulnasoft.default_branch', out::COLOR_CODE_YELLOW)
        master = out.wrap_in_color('master', out::COLOR_CODE_BLUE)
        fast = out.wrap_in_color('--fast', out::COLOR_CODE_YELLOW)

        raise UserInteractionRequired, "Your default KhulnaSoft branch is #{default_branch}. Please set #{setting} to #{master} to use #{fast}."
      end

      def stop_and_backup!
        Runit.stop(quiet: true)

        return true if backup_data

        KDK::Output.error('Failed to backup data.')
        display_help_message

        false
      end

      def reset_data_fast!
        KDK::Command::Stop.new.run
        sleep 5
        result = KDK.make('ensure-databases-setup')
        unless result.success?
          KDK::Output.error('Failed to reset data.', result.stderr_str)
          display_help_message

          return false
        end

        rake = KDK::Execute::Rake.new(%w[db:create])
        unless rake.execute_in_khulnasoft(retry_attempts: 3).success?
          KDK::Output.error('Failed to create databases.', rake.stderr_output)
          display_help_message

          return false
        end

        helper = KDK::PackageHelper.new(package: :kdk_preseeded_db)
        package_path = helper.download_package(skip_cache: true, return_path: true)

        KDK::Shellout.new(%W[tar xf #{package_path}]).stream

        cmd = KDK::Postgresql.new.psql_cmd([])
        pid = Kernel.spawn(*cmd, in: 'postgres.sql', out: File::NULL)
        _, status = Process.wait2(pid)
        out.abort("Failed to restore database from postgres.sql (exit code: #{status.exitstatus})") unless status.success?

        out.notice('Successfully reset with preeseeded database!')
        out.info("Migrations may be pending. If KDK restart fails, try: #{out.wrap_in_color('kdk rails db:migrate', out::COLOR_CODE_YELLOW)}")
        true
      ensure
        FileUtils.rm_f(package_path) if defined?(package_path) && package_path.is_a?(String)
        FileUtils.rm_f(config.kdk_root.join('postgres.sql'))
      end

      def reset_data!
        result = KDK.make('khulnasoft-topology-service-setup', 'ensure-databases-setup', 'reconfigure')

        if result.success?
          KDK::Output.notice('Successfully reset data!')
          KDK::Command::Start.new.run
        else
          KDK::Output.error('Failed to reset data.', result.stderr_str)
          display_help_message

          false
        end
      end

      def continue?
        KDK::Output.warn("We're about to remove _all_ (KhulnaSoft and praefect) PostgreSQL data, Rails uploads and git repository data.")
        KDK::Output.warn("Backups will be made in '#{KDK.root.join('.backups')}', just in case!")

        return true if ENV.fetch('KDK_RESET_DATA_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

        KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def backup_data
        move_postgres_data && move_redis_dump_rdb && move_rails_uploads && move_git_repository_data
      end

      def current_timestamp
        @current_timestamp ||= Time.now.strftime('%Y-%m-%d_%H.%M.%S')
      end

      def create_directory(directory)
        directory = kdk_root_pathed(directory)
        Dir.mkdir(directory) unless directory.exist?

        true
      rescue Errno::ENOENT => e
        KDK::Output.error("Failed to create directory '#{directory}' - #{e}", e)
        false
      end

      def backup_path(message, *path)
        path_to_backup = kdk_backup_pathed_timestamped(*path)
        path = kdk_root_pathed(*path)
        return true unless path.exist?

        KDK::Output.notice("Moving #{message} from '#{path}' to '#{path_to_backup}/'")

        # Ensure the base path exists
        FileUtils.mkdir_p(path_to_backup.dirname)
        FileUtils.mv(path, path_to_backup)

        true
      rescue SystemCallError => e
        KDK::Output.error("Failed to rename path '#{path}' to '#{path_to_backup}/' - #{e}", e)
        false
      end

      def kdk_backup_pathed_timestamped(*path)
        path = path.flatten
        path[-1] = "#{path[-1]}.#{current_timestamp}"
        KDK.root.join('.backups', *path)
      end

      def kdk_root_pathed(*path)
        KDK.root.join(*path.flatten)
      end

      def move_postgres_data
        backup_path('PostgreSQL data', %w[postgresql data])
      end

      def move_redis_dump_rdb
        backup_path('redis dump.rdb', %w[redis dump.rdb])
      end

      def move_rails_uploads
        backup_path('Rails uploads', %w[khulnasoft public uploads])
      end

      def move_git_repository_data
        backup_path('git repository data', 'repositories') &&
          restore_repository_data_dir &&
          backup_path('more git repository data', 'repository_storages')
      end

      def restore_repository_data_dir
        FileUtils.mkdir_p('repositories')
        true
      end

      def touch_file(file)
        FileUtils.touch(file)
        true
      rescue SystemCallError
        false
      end
    end
  end
end
