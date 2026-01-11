# frozen_string_literal: true

module KDK
  module Command
    # Run rake tasks through KDK
    class Rake < BaseCommand
      def run(args = [])
        # Yeah, it's really this simple, lol.
        #
        # This avoids polluting the environment with `BUNDLER_SETUP` and
        # `RUBYOPT` variables by `bundle exec`, which causes issues in
        # some Ruby child processes.
        ::Rake.application.run(args)

        true
      end
    end
  end
end
