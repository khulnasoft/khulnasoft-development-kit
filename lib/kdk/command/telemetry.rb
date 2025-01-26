# frozen_string_literal: true

module KDK
  module Command
    class Telemetry < BaseCommand
      def run(_ = [])
        puts KDK::Telemetry::PROMPT_TEXT

        username = $stdin.gets&.chomp
        KDK::Telemetry.update_settings(username)

        puts tracking_message

        true
      rescue Interrupt
        puts
        puts "Keeping previous behavior: #{tracking_message}"

        true
      end

      private

      def tracking_message
        return 'Error tracking and analytic data will not be collected.' unless KDK::Telemetry.telemetry_enabled?

        username = config.telemetry.username

        case username
        when '.'
          'Error tracking and analytic data will not be collected.'
        when '', NilClass
          'Error tracking and analytic data will now be collected anonymously.'
        else
          "Error tracking and analytic data will now be collected as '#{username}'."
        end
      end
    end
  end
end
