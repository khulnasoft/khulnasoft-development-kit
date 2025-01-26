# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Flags use of strftime('%Y-%m-%d') for formatting dates
      # the preferred method is using .iso8601
      #
      # @example
      #   # bad
      #   DateTime.now.strftime('%Y-%m-%d')
      #   Time.now.strftime("%Y-%m-%d")
      #   Date.today.strftime("%Y-%m-%d")
      #
      #   # good
      #   DateTime.now.to_date.iso8601
      #   Time.now.to_date.iso8601
      #   Date.today.iso8601
      #
      # See also:
      # - https://khulnasoft.com/khulnasoft-org/khulnasoft/-/issues/410638
      class Iso8601Date < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector
        include RangeHelp

        MSG = 'Use `iso8601` instead of `strftime("%Y-%m-%d")`.'
        RESTRICT_ON_SEND = [:strftime].freeze

        # @!method strftime_iso8601?(node)
        def_node_matcher :strftime_iso8601?, <<~PATTERN
        (send $(...) :strftime (str "%Y-%m-%d"))
        PATTERN

        def on_send(node)
          return unless strftime_iso8601?(node)

          range = range_between(node.loc.selector.begin_pos, node.loc.end.end_pos)

          add_offense(range) do |corrector|
            corrector.replace(range, 'to_date.iso8601')
          end
        end
      end
    end
  end
end
