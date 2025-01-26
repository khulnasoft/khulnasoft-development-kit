# frozen_string_literal: true

module RuboCop
  module Cop
    module KhulnasoftSecurity
      # Check for use of redirect_to(params.update())
      #
      # Passing user params to the redirect_to method provides an open redirect
      #
      # @example
      #
      #   # bad
      #   redirect_to(params.update(action: 'main'))
      #
      #   # good
      #   redirect_to(allowed(params))
      #
      class RedirectToParamsUpdate < RuboCop::Cop::Base
        MSG = 'Avoid using `redirect_to(params.%<name>s(...))`. ' \
          'Only pass allowed arguments into redirect_to() (e.g. not including `host`)'

        # @!method redirect_to_params_update_node(node)
        def_node_matcher :redirect_to_params_update_node, <<-PATTERN
           (send nil? :redirect_to $(send (send nil? :params) ${:update :merge} ...))
        PATTERN

        def on_send(node)
          selected, name = redirect_to_params_update_node(node)
          return unless name

          message = format(MSG, name: name)

          add_offense(selected, message: message)
        end
      end
    end
  end
end
