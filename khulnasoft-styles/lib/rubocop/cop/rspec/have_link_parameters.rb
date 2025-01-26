# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks for unused parameters to the `have_link` matcher.
      #
      # @example
      #
      #   # bad
      #   expect(page).to have_link('Link', 'https://example.com')
      #
      #   # good
      #   expect(page).to have_link('Link', href: 'https://example.com')
      #   expect(page).to have_link('Example')
      class HaveLinkParameters < Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = "The second argument to `have_link` should be a Hash."

        # @!method unused_parameters?(node)
        def_node_matcher :unused_parameters?, <<~PATTERN
          (send nil? :have_link
            _ !{hash nil}
          )
        PATTERN

        def on_send(node)
          return unless unused_parameters?(node)

          location = node.arguments[1..]
                       .map(&:source_range)
                       .reduce(:join)

          add_offense(location, message: MESSAGE) do |corrector|
            corrector.insert_after(location.end, "\n")
          end
        end
      end
    end
  end
end
