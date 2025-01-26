# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if there is an empty line after the last include/extend/prepend.
      #
      # @example
      #   # bad
      #   class Hello
      #     include Something1
      #     include Something2
      #     def world
      #     end
      #   end

      #   # good
      #   class Hello
      #     include Something1
      #     include Something2
      #
      #     def world
      #     end
      #   end
      class LineBreakAfterFinalMixin < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Add an empty line after the last `%<mixin>s`.'

        MIXIN_METHODS = %i[include extend prepend].to_set.freeze

        # @!method mixin?(node)
        def_node_matcher :mixin?, <<~PATTERN
          (send {nil? | self} MIXIN_METHODS ...)
        PATTERN

        def on_class(node)
          return unless node.body

          mixins = node.body.child_nodes.select { |child| mixin?(child) }

          return if mixins.empty?

          last_mixin = mixins.last

          return if next_line_valid?(last_mixin)

          add_offense(last_mixin, message: format(MSG, mixin: last_mixin.method_name)) do |corrector|
            corrector.insert_after(last_mixin, "\n")
          end
        end

        private

        def next_line_valid?(node)
          next_line = next_line(node)

          empty_line?(next_line) || end_line?(next_line)
        end

        def next_line(node)
          processed_source[node.loc.line]
        end

        def empty_line?(line)
          line.empty?
        end

        def end_line?(line)
          /^\s*end\b/.match?(line)
        end
      end
    end
  end
end
