# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk update` command execution
    class Update < BaseCommand
      def run(_args = [])
        success = update!

        success = run_rake_reconfigure if success && config.kdk.auto_reconfigure?

        if success
          Announcements.new.render_all
          KDK::Output.success('Successfully updated!')
        else
          KDK::Output.error('Failed to update.')
          display_help_message
        end

        success
      end

      private

      def update!
        KDK::Hooks.with_hooks(config.kdk.update_hooks, 'kdk update') do
          # Run `self-update` first to make sure Makefiles are up-to-date.
          # This ensures the next `make update` call works with the latest updates and instructions.
          if self_update?
            result = self_update!
            next false unless result
          end

          old_env = ENV.to_h
          ENV.merge! update_env

          run_rake_update
        ensure
          update_env.keys.map { |k| ENV.delete(k) }
          ENV.merge! old_env || {}
        end
      end

      def self_update!
        previous_revision = current_git_revision
        sh = KDK.make('self-update')

        return false unless sh.success?

        if previous_revision != current_git_revision
          Dir.chdir(config.kdk_root.to_s)
          ENV['KDK_SELF_UPDATE'] = '0'
          Kernel.exec 'kdk update'
        end

        true
      end

      def self_update?
        %w[1 yes true].include?(ENV.fetch('KDK_SELF_UPDATE', '1'))
      end

      def update_env
        {
          'PG_AUTO_UPDATE' => '1',
          'KDK_SKIP_MAKEFILE_TIMEIT' => '1'
        }
      end

      def current_git_revision
        Shellout.new(%w[git rev-parse HEAD], chdir: config.kdk_root).run
      end

      def run_rake_reconfigure
        Rake::Task[:reconfigure].invoke
        true
      rescue RuntimeError => e
        KDK::Output.error(e.message)
        false
      end

      def run_rake_update
        Rake::Task[:update].invoke
        true
      rescue RuntimeError => e
        KDK::Output.error(e.message)
        false
      end
    end
  end
end
