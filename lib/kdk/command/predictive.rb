# frozen_string_literal: true

module KDK
  module Command
    class Predictive < BaseCommand
      help 'Run relevant tests for your local changes, whether committed or not'

      def run(args = [])
        success = true
        begin
          force = !!args.delete('--yes')
          success = KDK::Predictive::Rspec.new.execute(force: force) && success if args.empty? || args.include?('--rspec')
        rescue StandardError => e
          out.error("RSpec test execution failed: #{e.message}", e, report_error: true)
          success = false
        end

        begin
          success = KDK::Predictive::Jest.new.execute && success if args.empty? || args.include?('--jest')
        rescue StandardError => e
          out.error("Jest test execution failed: #{e.message}", e, report_error: true)
          success = false
        end

        success
      end
    end
  end
end
