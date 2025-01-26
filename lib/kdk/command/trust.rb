# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk trust` command execution
    #
    # @deprecated KDK trust command has been deprecated should be removed in a future update
    class Trust < BaseCommand
      def run(_args = [])
        KDK::Output.info("'kdk trust' is deprecated and no longer required.")

        true
      end
    end
  end
end
