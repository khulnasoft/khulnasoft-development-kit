# frozen_string_literal: true

module KDK
  module Command
    class Doctor < BaseCommand
      def initialize(diagnostics: KDK::Diagnostic.all, **args)
        @diagnostics = diagnostics
        @unexpected_error = false

        super(**args)
      end

      def run(_ = [])
        unless installed?
          out.warn("KDK has not been installed so cannot run 'kdk doctor'. Try running `gem install khulnasoft-development-kit` again.")
          return false
        end

        start_necessary_services

        if diagnostic_results.empty?
          show_healthy

          true
        else
          show_results

          return 2 if @unexpected_error

          false
        end
      end

      private

      attr_reader :diagnostics

      def installed?
        # TODO: Eventually, the Procfile will no longer exists so we need a better
        # way to determine this, but this will be OK for now.
        KDK.root.join('Procfile').exist?
      end

      def diagnostic_results
        @diagnostic_results ||= jobs.filter_map { |x| x.join[:results] }
      end

      def jobs
        diagnostics.map do |diagnostic|
          Thread.new do
            Thread.current[:results] = perform_diagnosis_for(diagnostic)
            out.print(output_dot, stderr: true)
          end
        end
      end

      def perform_diagnosis_for(diagnostic)
        diagnostic.message unless diagnostic.success?
      rescue StandardError => e
        Thread.current[:unexpected_error] = true
        @unexpected_error = true
        diagnostic.message(([e.message] + e.backtrace).join("\n"))
      end

      def start_necessary_services
        Runit.start('postgresql', quiet: true)
        # Give services a chance to start up..
        sleep(2)
      end

      def show_healthy
        out.puts("\n")
        out.success('Your KDK is healthy.')
      end

      def show_results
        out.puts("\n")
        out.warn('Your KDK may need attention.')

        diagnostic_results.each do |result|
          out.puts(result)
        end
      end

      def output_dot
        return out.wrap_in_color('E', Output::COLOR_CODE_RED) if Thread.current[:unexpected_error]
        return out.wrap_in_color('W', Output::COLOR_CODE_YELLOW) if Thread.current[:results]

        out.wrap_in_color('.', Output::COLOR_CODE_GREEN)
      end
    end
  end
end
