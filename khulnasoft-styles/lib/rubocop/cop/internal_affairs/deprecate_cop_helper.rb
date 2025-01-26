# frozen_string_literal: true

module Rubocop
  module Cop
    module InternalAffairs
      # Cop that denies the use of CopHelper.
      class DeprecateCopHelper < RuboCop::Cop::Base
        MSG = 'Do not use `CopHelper` or methods from it, use improved patterns described in https://www.rubydoc.info/gems/rubocop/RuboCop/RSpec/ExpectOffense'

        # @!method cop_helper(node)
        def_node_matcher :cop_helper, <<~PATTERN
          (send nil? ${:include :extend :prepend}
            (const _ {:CopHelper}))
        PATTERN

        # @!method cop_helper_method(node)
        def_node_search :cop_helper_method, <<~PATTERN
          (send nil? {:inspect_source :inspect_source_file :parse_source :autocorrect_source_file :autocorrect_source :_investigate} ...)
        PATTERN

        # @!method cop_helper_method_on_instance(node)
        def_node_search :cop_helper_method_on_instance, <<~PATTERN
          (send (send nil? _) {:messages :highlights :offenses} ...)
        PATTERN

        def on_send(node)
          cop_helper(node) do
            add_offense(node)
          end

          cop_helper_method(node) do
            add_offense(node)
          end

          cop_helper_method_on_instance(node) do
            add_offense(node)
          end
        end
      end
    end
  end
end
