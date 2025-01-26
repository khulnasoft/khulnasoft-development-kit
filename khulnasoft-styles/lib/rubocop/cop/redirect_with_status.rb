# frozen_string_literal: true

module Rubocop
  module Cop
    # Prevents usage of 'redirect_to' in actions 'destroy' and 'destroy_all'
    # without specifying 'status'.
    #
    # @example
    #   # bad
    #
    #   def destroy
    #     redirect_to root_path
    #   end
    #
    #   def destroy_all
    #     redirect_to root_path, alert: 'Oh no!'
    #   end
    #
    #   # good
    #
    #   def destroy
    #     redirect_to root_path, status: 302
    #   end
    #
    #   def destroy_all
    #     redirect_to root_path, alert: 'Oh no!', status: 302
    #   end
    #
    #   def show
    #     redirect_to root_path
    #   end
    #
    # See https://khulnasoft.com/khulnasoft-org/khulnasoft-ce/issues/31840
    class RedirectWithStatus < RuboCop::Cop::Base
      MSG = 'Do not use "redirect_to" without "status" in "%<name>s" action.'

      RESTRICT_ON_SEND = %i[redirect_to].freeze

      ACTIONS = %i[destroy destroy_all].to_set.freeze

      # @!method redirect_to_with_status?(node)
      def_node_matcher :redirect_to_with_status?, <<~PATTERN
        (send nil? :redirect_to ...
          (hash <(pair (sym :status) _) ...>)
        )
      PATTERN

      def on_send(node)
        return if redirect_to_with_status?(node)

        node.each_ancestor(:def) do |def_node|
          next unless ACTIONS.include?(def_node.method_name)

          message = format(MSG, name: def_node.method_name)
          add_offense(node.loc.selector, message: message)
        end
      end
    end
  end
end
