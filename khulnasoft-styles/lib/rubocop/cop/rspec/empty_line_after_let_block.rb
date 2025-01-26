# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks if there is an empty line after let blocks.
      #
      # @example
      #   # bad
      #   RSpec.describe Foo do
      #     let(:something) { 'something' }
      #     let(:another_thing) do
      #     end
      #     let(:something_else) do
      #     end
      #     let(:last_thing) { 'last thing' }
      #   end
      #
      #   # good
      #   RSpec.describe Foo do
      #     let(:something) { 'something' }
      #     let(:another_thing) do
      #     end
      #
      #     let(:something_else) do
      #     end
      #
      #     let(:last_thing) { 'last thing' }
      #   end
      #
      #   # good - it's ok to have non-separated without do/end blocks
      #   RSpec.describe Foo do
      #     let(:something) { 'something' }
      #     let(:last_thing) { 'last thing' }
      #   end
      #
      class EmptyLineAfterLetBlock < Base
        extend RuboCop::Cop::AutoCorrector
        include RuboCop::Cop::RSpec::EmptyLineSeparation

        MSG = 'Add an empty line after `%<let>s` block.'

        def on_block(node)
          RuboCop::RSpec::ExampleGroup.new(node).lets.each do |let|
            break if last_child?(let)
            next if let.single_line?

            missing_separating_line_offense(let) do |method|
              format(MSG, let: method)
              format(MSG, let: method)
            end
          end
        end
        alias_method :on_numblock, :on_block
      end
    end
  end
end
