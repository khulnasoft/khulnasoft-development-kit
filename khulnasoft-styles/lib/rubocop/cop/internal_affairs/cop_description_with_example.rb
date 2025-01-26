# frozen_string_literal: true

require 'rubocop/cop/internal_affairs/cop_description'
require 'rubocop/cop/mixin/documentation_comment'

module Rubocop
  module Cop
    module InternalAffairs
      # Enforces the cop description to start with a word such as verb, and to include good and bad examples
      #
      # @example
      #   # bad
      #   # This cop checks ....
      #   # @example
      #   #   # bad
      #   #   !array.empty?
      #   #
      #   #   # good
      #   #   array.any?
      #   class SomeCop < Base
      #     ....
      #   end
      #
      #   # bad
      #   # Checks ...
      #   class SomeCop < Base
      #     ...
      #   end
      #
      #   # good
      #   # Checks ...
      #   #
      #   # @example
      #   #   # bad
      #   #   !array.empty?
      #   #
      #   #   # good
      #   #   array.any?
      #   #
      #   class SomeCop < Base
      #     ...
      #   end
      class CopDescriptionWithExample < RuboCop::Cop::InternalAffairs::CopDescription
        include RuboCop::Cop::DocumentationComment
        extend RuboCop::Cop::AutoCorrector

        MSG_MISSING_EXAMPLES = 'Description should include good and bad examples'
        MSG_MISSING_DESCRIPTION = 'Must include a description'

        def on_class(node)
          super

          module_node = node.parent

          return unless module_node && node.parent_class

          return if description_includes_example?(node)

          description_beginning = first_comment_line(module_node)

          if description_beginning.nil?
            register_offense_for_missing_description(node)
          else
            register_offense_for_missing_examples(module_node, description_beginning)
          end
        end

        private

        def register_offense_for_missing_description(node)
          add_offense(node, message: MSG_MISSING_DESCRIPTION)
        end

        def register_offense_for_missing_examples(module_node, description_beginning)
          range = range(module_node, description_beginning)
          add_offense(range, message: MSG_MISSING_EXAMPLES)
        end

        def description_includes_example?(node)
          lines = preceding_lines(node)
          index_of_example = lines.index { |line| line.text.match?(/# @example( |$)/) }
          return false unless index_of_example

          lines_after_example = lines[index_of_example + 1..]

          lines_after_example.any? { |line| line.text.downcase.match?(/#   # good( |$)/) } &&
            lines_after_example.any? { |line| line.text.downcase.match?(/#   # bad( |$)/) }
        end
      end
    end
  end
end
