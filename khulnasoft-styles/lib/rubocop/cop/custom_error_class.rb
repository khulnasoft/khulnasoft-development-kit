# frozen_string_literal: true

module Rubocop
  module Cop
    # Makes sure that custom error classes, when empty, are declared
    # with Class.new.
    #
    # @example
    #   # bad
    #   class FooError < StandardError
    #   end
    #
    #   # okish
    #   class FooError < StandardError; end
    #
    #   # good
    #   FooError = Class.new(StandardError)
    class CustomErrorClass < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      MSG = 'Use `Class.new(SuperClass)` to define an empty custom error class.'

      def on_class(node)
        parent = node.parent_class
        body = node.body

        return if body

        parent_klass = class_name_from_node(parent)

        return unless parent_klass&.to_s&.end_with?('Error')

        add_offense(node) do |corrector|
          klass = node.identifier
          parent = node.parent_class

          replacement = "#{class_name_from_node(klass)} = Class.new(#{class_name_from_node(parent)})"

          corrector.replace(node, replacement)
        end
      end

      private

      # The nested constant `Foo::Bar::Baz` looks like:
      #
      #   s(:const,
      #     s(:const,
      #       s(:const, nil, :Foo), :Bar), :Baz)
      #
      # So recurse through that to get the name as written in the source.
      #
      def class_name_from_node(node, suffix = nil)
        return unless node&.type == :const

        name = node.children[1].to_s
        name = "#{name}::#{suffix}" if suffix

        if node.children[0]
          class_name_from_node(node.children[0], name)
        else
          name
        end
      end
    end
  end
end
