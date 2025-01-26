# frozen_string_literal: true

require 'rubocop-rspec'
require_relative 'base'

module Rubocop
  module Cop
    module RSpec
      # Checks for common mistakes in example descriptions.
      #
      # This cop will correct docstrings that begin/end with space or words that start with a capital letter.
      #
      # @see https://khulnasoft.com/khulnasoft-org/khulnasoft/-/merge_requests/46336#note_442669518
      #
      # @example
      #   # bad
      #   it 'Does something' do
      #   end
      #
      #   # good
      #   it 'does nothing' do
      #   end
      #
      # @example
      #   # bad
      #   it ' does something' do
      #   end
      #
      #   # good
      #   it 'does something' do
      #   end
      #
      # @example
      #   # bad
      #   it 'does something ' do
      #   end
      #
      #   # good
      #   it 'does something' do
      #   end
      #
      # @example
      #   # bad
      #   it ' does something ' do
      #   end
      #
      #   # good
      #   it 'does something' do
      #   end
      class ExampleStartingCharacter < Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.'

        # @!method it_description(node)
        def_node_matcher :it_description, <<-PATTERN
      (block (send _ :it ${
        (str $_)
        (dstr (str $_ ) ...)
      } ...) ...)
        PATTERN

        def on_block(node)
          it_description(node) do |description_node, _message|
            add_wording_offense(description_node, MSG) if invalid_description?(text(description_node))
          end
        end
        alias_method :on_numblock, :on_block

        private

        def add_wording_offense(node, message)
          docstring = docstring(node)
          add_offense(docstring, message: message) do |corrector|
            corrector.replace(docstring, replacement_text(node))
          end
        end

        def docstring(node)
          expr = node.source_range

          Parser::Source::Range.new(
            expr.source_buffer,
            expr.begin_pos + 1,
            expr.end_pos - 1
          )
        end

        def invalid_description?(message)
          message.match?(/(^([A-Z]{1}[a-z]+\s|\s)|\s$)/)
        end

        def replacement_text(node)
          text = text(node)

          text.strip!

          text = downcase_first_letter(text) if invalid_description?(text)

          text
        end

        # Recursive processing is required to process nested dstr nodes
        # that is the case for \-separated multiline strings with interpolation.
        def text(node)
          case node.type
          when :dstr
            node.node_parts.map { |child_node| text(child_node) }.join
          when :str
            node.value
          when :begin
            node.source
          end
        end

        def downcase_first_letter(str)
          str[0].downcase + str[1..]
        end
      end
    end
  end
end
