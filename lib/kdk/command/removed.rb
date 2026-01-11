# frozen_string_literal: true

module KDK
  module Command
    # Builds a command placeholder to indicate it's removed.
    module Removed
      def self.new(message)
        Class.new(BaseCommand) do
          define_method(:run) do |_args = []|
            out.warn 'This command was removed!'
            out.info message

            false
          endrestart.rb
        end
      end
    end
  end
end
