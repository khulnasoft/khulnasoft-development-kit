# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Flags if `RESTRICT_ON_SEND` constant not defined and method name is
      # checked programmatically in `on_send` methods.
      #
      # @example
      #   # bad
      #   def on_send(node)
      #     return unless method_name(node) == :foo
      #     return unless node.children[1] == :foo
      #     return unless METHOD_NAMES.include?(method_name(node))
      #
      #     name = node.children[1]
      #     return unless name == :foo
      #     name2 = method_name(node)
      #     return unless name == :foo
      #
      #     # more code
      #   end
      #
      #   # good
      #   RESTRICT_ON_SEND = %i[foo].freeze
      #
      #   def on_send(node)
      #     # more code
      #   end
      #
      #   # ignored - not `on_send`
      #   def on_def(node)
      #     return unless method_name(node) == :foo
      #   end
      #
      #   # ignored - `else` branch
      #   def on_send(node)
      #     if method_name(node) == :foo
      #       add_offense(node)
      #     else
      #       something_else
      #     end
      #   end
      class UseRestrictOnSend < Base
        MSG = 'Define constant `RESTRICT_ON_SEND` to speed up calls to `on_send`. ' \
          'The following line is then no longer necessary:'

        # @!method method_name_plain(node)
        def_node_matcher :method_name_plain, <<~PATTERN
          {
            (send _ :method_name _ ...)       # method_name(node)
            (send
              (send _ :children) :[] (int 1)  # node.children[1]
            )
          }
        PATTERN

        # @!method method_name_call(node)
        def_node_matcher :method_name_call, <<~PATTERN
          {
            #method_name_plain
            (lvar %1)
          }
        PATTERN

        # @!method method_name_assignment(node)
        def_node_search :method_name_assignment, <<~PATTERN
          (lvasgn $_name #method_name_plain)
        PATTERN

        # @!method method_name_check(node)
        def_node_search :method_name_check, <<~PATTERN
          (if
            ${
              (send #method_name_call(%1) {:== :!=} _) # method_name(node) == foo
              (send _ :include? #method_name_call(%1)) # a.include?(method_name(node))
            }
            {!nil? nil? | nil? !nil?}                  # has either `if` or `else` branch - not both
          )
        PATTERN

        def on_def(node)
          return unless node.method?(:on_send)
          return if @restrict_on_send_set

          local_assignments = method_name_assignment(node).to_set

          method_name_check(node, local_assignments) do |call_node|
            add_offense(call_node)
          end
        end

        def on_casgn(node)
          @restrict_on_send_set = true if node.name == :RESTRICT_ON_SEND
        end
      end
    end
  end
end
