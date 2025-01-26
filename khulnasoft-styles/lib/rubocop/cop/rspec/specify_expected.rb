# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks whether `specify` is used with `is_expected` and suggests the
      # use of `it`.
      #
      # @example
      #
      #   # bad
      #   specify { is_expected.to eq(true) }
      #
      #   # good
      #   it { is_expected.to eq(true) }
      #
      class SpecifyExpected < Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Prefer using `it` when used with `is_expected`.'

        # @!method specify_with_expected?(node)
        def_node_matcher :specify_with_expected?, <<~PATTERN
          (block
            (send nil? :specify ...)
            _args
            (send
              (send nil? :is_expected)
              ...
            )
          )
        PATTERN

        RESTRICT_ON_SEND = %i[specify].freeze

        def on_send(node)
          return unless specify_with_expected?(node.parent)

          add_offense(node) do |corrector|
            corrector.replace(node, 'it')
          end
        end
      end
    end
  end
end
