# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks if there is an empty line after shared example blocks.
      #
      # @example
      #   # bad
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this' do
      #     end
      #     it_behaves_like 'does that' do
      #     end
      #     it_behaves_like 'do some more'
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this' do
      #     end
      #
      #     it_behaves_like 'does that' do
      #     end
      #
      #     it_behaves_like 'do some more'
      #   end
      #
      #   # fair - it's ok to have non-separated without blocks
      #   RSpec.describe Foo do
      #     it_behaves_like 'do this first'
      #     it_behaves_like 'does this'
      #   end
      #
      class EmptyLineAfterSharedExample < Base
        extend RuboCop::Cop::AutoCorrector
        include RuboCop::Cop::RSpec::EmptyLineSeparation

        MSG = 'Add an empty line after `%<example>s` block.'

        # @!method shared_examples(node)
        def_node_matcher :shared_examples, <<~PATTERN
          {
            (block (send #rspec? #SharedGroups.all ...) ...)
            {
              (block (send nil? #Includes.all ...) ...)
              (send nil? #Includes.all ...)
            }
          }
        PATTERN

        def on_block(node)
          shared_examples(node) do
            break if last_child?(node)

            missing_separating_line_offense(node) do |method|
              format(MSG, example: method)
            end
          end
        end
        alias_method :on_numblock, :on_block
      end
    end
  end
end
