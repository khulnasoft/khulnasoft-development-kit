# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks for single-line hook blocks
      #
      # @example
      #
      #   # bad
      #   before { do_something }
      #   after(:each) { undo_something }
      #
      #   # good
      #   before do
      #     do_something
      #   end
      #
      #   after(:each) do
      #     undo_something
      #   end
      class SingleLineHook < Base
        MESSAGE = "Don't use single-line hook blocks."

        # @!method rspec_hook?(node)
        def_node_search :rspec_hook?, <<~PATTERN
          (send nil? {:after :around :before} ...)
        PATTERN

        def on_block(node)
          return unless node.single_line?
          return unless rspec_hook?(node)

          add_offense(node, message: MESSAGE)
        end
        alias_method :on_numblock, :on_block
      end
    end
  end
end
