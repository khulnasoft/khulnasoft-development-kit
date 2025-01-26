# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk install` command execution
    #
    # This command accepts the following parameters:
    # - khulnasoft_repo=<url to repository> (defaults to: "https://khulnasoft.com/khulnasoft-org/khulnasoft")
    # - telemetry_user=<string>
    #   - if option is given, defaults to: "" which enables telemetry for randomized username
    #   - if option is missing, does not update telemetry which is disabled by default
    class Install < BaseCommand
      def run(args = [])
        args.each do |arg|
          case arg
          when /^telemetry_user=(.*)/
            KDK::Telemetry.update_settings(Regexp.last_match(1))
          end
        end

        result = KDK.make('install', *args)

        unless result.success?
          KDK::Output.error('Failed to install.', result.stderr_str)
          display_help_message
        end

        Announcements.new.cache_all if result.success?

        result.success?
      end
    end
  end
end
