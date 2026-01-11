# frozen_string_literal: true

module KDK
  module Command
    # Run IRB console with KDK environment loaded
    class Console < BaseCommand
      help 'Run IRB console with KDK environment loaded'

      def run(_ = [])
        require 'irb'
        IRB.start
        true
      end
    end
  end
end
