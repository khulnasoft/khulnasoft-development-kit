# frozen_string_literal: true

require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Flags useless dynamic hook/let definitions via `.each`, `.each_key`, or
      # `.each_value` without defining a wrapping `context` explicitly inside
      # the loop block. Without it, the let definition will always/only be set
      # to the final value.
      #
      # @example
      #
      #   # bad
      #   context 'foo' do
      #     [true, false].each do |bool|
      #       before do
      #         stub_something(bool: bool)
      #       end
      #
      #       let(:foo) { build(:model, bool: bool) }
      #
      #       it 'works' do
      #         # `bool` is always `false`
      #       end
      #     end
      #   end
      #
      #   # good
      #   context 'foo' do
      #     [true, false].each do |bool|
      #       context "with bool #{bool}" do # <--
      #         before do
      #           stub_something(bool: bool)
      #         end
      #
      #         let(:foo) { build(:model, bool: bool) }
      #
      #         it 'works' do
      #           # `bool` is `true` and then `false`
      #         end
      #       end
      #     end
      #   end
      class UselessDynamicDefinition < Base
        MSG = 'Avoid useless dynamic definitions without `context`.'

        RESTRICT_ON_SEND = %i[each each_key each_value].freeze

        def on_send(node)
          return unless dynamic_definition?(node.parent)

          add_offense(node.loc.selector)
        end

        private

        def dynamic_definition?(node)
          group = RuboCop::RSpec::ExampleGroup.new(node)

          group.lets.any? || group.hooks.any?
        end
      end
    end
  end
end
