# frozen_string_literal: true

module KDK
  module Diagnostic
    class Version < Base
      TITLE = 'KDK Version'
      DEFAULT_BRANCH = 'main'

      def success?
        !behind_origin_default_branch?
      end

      def detail
        return if success?

        'An update for KDK is available.'
      end

      private

      def behind_origin_default_branch?
        @behind_origin_default_branch ||= begin
          run(%w[git fetch])
          run(%W[git rev-list --left-only --count origin/#{DEFAULT_BRANCH}...@]).to_i.positive?
        end
      end

      def run(cmd)
        Shellout.new(cmd, chdir: config.kdk_root).run
      end
    end
  end
end
