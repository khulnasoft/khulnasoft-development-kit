# frozen_string_literal: true

require 'rake'

module KDK
  module Command
    class Cleanup < BaseCommand
      def run(_ = [])
        return true unless continue?

        execute
      end

      private

      def continue?
        KDK::Output.warn("About to perform the following actions:")
        KDK::Output.puts(stderr: true)
        KDK::Output.puts('- Truncate khulnasoft/log/* files', stderr: true)

        if unnecessary_installed_versions_of_software.any?
          KDK::Output.puts(stderr: true)
          KDK::Output.puts('- Uninstall any asdf software that is not defined in .tool-versions:', stderr: true)
          unnecessary_installed_versions_of_software.each do |name, versions|
            KDK::Output.puts("#{name} #{versions.keys.join(' ')}")
          end

          KDK::Output.puts(stderr: true)
          KDK::Output.puts('Run `KDK_CLEANUP_SOFTWARE=false kdk cleanup` to skip uninstalling software.')
        end

        KDK::Output.puts(stderr: true)

        return true if ENV.fetch('KDK_CLEANUP_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

        result = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
        KDK::Output.puts(stderr: true)

        result
      end

      def delete_software?
        ENV.fetch('KDK_CLEANUP_SOFTWARE', 'true') == 'true'
      end

      def execute
        truncate_log_files
        uninstall_unnecessary_software
      rescue StandardError => e
        KDK::Output.error(e)
        false
      end

      def truncate_log_files
        execute_rake_task('khulnasoft:truncate_logs', 'khulnasoft.rake', args: 'false')
      end

      def unnecessary_installed_versions_of_software
        return [] unless delete_software?

        @unnecessary_installed_versions_of_software ||=
          Asdf::ToolVersions.new.unnecessary_installed_versions_of_software.sort_by { |name, _| name }
      end

      def uninstall_unnecessary_software
        return true if unnecessary_installed_versions_of_software.empty?

        execute_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake', args: 'false')
      end

      def execute_rake_task(task_name, rake_file, args: nil)
        Kernel.load(KDK.root.join('lib', 'tasks', rake_file))

        Rake::Task[task_name].invoke(args)
        true
      rescue RuntimeError => e
        KDK::Output.error(e)
        false
      end
    end
  end
end
