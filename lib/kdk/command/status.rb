# frozen_string_literal: true

module KDK
  module Command
    # Display status of all enabled services or specified ones only
    class Status < BaseCommand
      def run(args = [])
        Runit.sv('status', args).tap do
          print_ready_message if args.empty?
        end
      end
    end
  end
end
