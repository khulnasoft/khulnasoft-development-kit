# frozen_string_literal: true

module Rubocop
  module Cop
    module Style
      # Flags uses of OpenStruct, as it is now officially discouraged
      # to be used for performance, version compatibility, and potential security issues.
      #
      # @example
      #   # bad
      #   class SubClass < OpenStruct
      #   end
      #
      #   # good
      #   class SubClass
      #   end
      #
      # See also:
      # - https://rubyreferences.github.io/rubychanges/3.0.html#standard-library
      # - https://docs.ruby-lang.org/en/3.0.0/OpenStruct.html#class-OpenStruct-label-Caveats
      # - https://khulnasoft.com/khulnasoft-org/khulnasoft/-/merge_requests/67855
      class OpenStructUse < RuboCop::Cop::Base
        MSG = 'Avoid using `OpenStruct`. It is officially discouraged. ' \
          'Replace it with `Struct`, `Hash`, or RSpec doubles. ' \
          'See https://docs.ruby-lang.org/en/3.0.0/OpenStruct.html#class-OpenStruct-label-Caveats'

        # @!method uses_open_struct?(node)
        def_node_matcher :uses_open_struct?, <<-PATTERN
          (const {nil? (cbase)} :OpenStruct)
        PATTERN

        def on_const(node)
          return unless uses_open_struct?(node)
          return if custom_class_or_module_definition?(node)

          add_offense(node)
        end

        private

        def custom_class_or_module_definition?(node)
          parent = node.parent

          (parent.class_type? || parent.module_type?) && node.left_siblings.empty?
        end
      end
    end
  end
end
