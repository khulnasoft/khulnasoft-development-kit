# frozen_string_literal: true

module Rubocop
  module Cop
    # Checks for return inside blocks.
    # For more information see: https://khulnasoft.com/khulnasoft-org/khulnasoft-foss/issues/42889
    #
    # @example
    #   # bad
    #   call do
    #     return if something
    #
    #     do_something_else
    #   end
    #
    #   # good
    #   call do
    #     break if something
    #
    #     do_something_else
    #   end
    #
    class AvoidReturnFromBlocks < RuboCop::Cop::Base
      MSG = 'Do not return from a block, use next or break instead.'
      DEF_METHODS = %i[define_method lambda].freeze
      ALLOWED_METHODS = %i[each each_filename times loop].freeze

      def on_block(node)
        block_body = node.body

        return unless block_body
        return unless top_block?(node)

        block_body.each_node(:return) do |return_node|
          next if parent_blocks(node, return_node).all? { |block| allowed?(block) }

          add_offense(return_node)
        end
      end

      alias_method :on_numblock, :on_block

      private

      def top_block?(node)
        current_node = node
        top_block = nil

        while current_node && current_node.type != :def
          top_block = current_node if current_node.block_type?
          current_node = current_node.parent
        end

        top_block == node
      end

      def parent_blocks(node, current_node)
        blocks = []

        until node == current_node || def?(current_node)
          blocks << current_node if current_node.block_type?
          current_node = current_node.parent
        end

        blocks << node if node == current_node && !def?(node)
        blocks
      end

      def def?(node)
        node.def_type? || node.defs_type? ||
          (node.block_type? && DEF_METHODS.include?(node.method_name))
      end

      def allowed?(block_node)
        ALLOWED_METHODS.include?(block_node.method_name)
      end
    end
  end
end
