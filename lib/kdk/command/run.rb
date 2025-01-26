# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk run` command execution
    #
    # @deprecated KDK run command has been deprecated should be removed in a future update
    class Run < BaseCommand
      def run(_args = [])
        abort <<~KDK_RUN_NO_MORE
          'kdk run' is no longer available; see doc/runit.md.

          Use 'kdk start', 'kdk stop', and 'kdk tail' instead.
        KDK_RUN_NO_MORE
      end
    end
  end
end
