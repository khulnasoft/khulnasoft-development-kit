# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/internal_affairs/use_restrict_on_send'

RSpec.describe RuboCop::Cop::InternalAffairs::UseRestrictOnSend do
  shared_examples 'checking for missing RESTRICT_ON_SEND' do |snippet|
    context "with snippet `#{snippet}`" do
      it 'flags condition using equality operators' do
        expect_offense(<<~RUBY, snippet: snippet)
          def on_send(node)
            return unless %{snippet} == :some_method_name
                          ^{snippet}^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]

            return if %{snippet} != :some_method_name
                      ^{snippet}^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]

            if %{snippet} == :some_method_name
               ^{snippet}^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end

            unless %{snippet} != :some_method_name
                   ^{snippet}^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end
          end
        RUBY
      end

      it 'flags condition using equality operators with local assignment' do
        expect_offense(<<~RUBY, snippet: snippet)
          def on_send(node)
            name = %{snippet}
            return if name == :some_method_name
                      ^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
            return unless name != :some_method_name
                          ^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]

            name2 = %{snippet}
            if name2 == :some_method_name
               ^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end

            unless name2 != :some_method_name
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end
          end
        RUBY
      end

      it 'ignores condition using equality operators with `else` branches' do
        expect_no_offenses(<<~RUBY)
          def on_send(node)
            if #{snippet} == :some_method_name
              add_offense(node)
            else
              something_else
            end

            unless #{snippet} != :some_method_name
              add_offense(node)
            else
              something_else
            end

            name = #{snippet}
            if name == :some_method_name
              add_offense(node)
            else
              something_else
            end

            name2 = #{snippet}
            unless name2 != :some_method_name
              add_offense(node)
            else
              something_else
            end
          end
        RUBY
      end

      it 'flags condition using `Array#include?`' do
        expect_offense(<<~RUBY, snippet: snippet)
          def on_send(node)
            return if METHOD_NAMES.include?(%{snippet})
                      ^^^^^^^^^^^^^^^^^^^^^^^{snippet}^ Define constant `RESTRICT_ON_SEND`[...]
            return unless METHOD_NAMES.include?(%{snippet})
                          ^^^^^^^^^^^^^^^^^^^^^^^{snippet}^ Define constant `RESTRICT_ON_SEND`[...]

            if METHOD_NAMES.include?(%{snippet})
               ^^^^^^^^^^^^^^^^^^^^^^^{snippet}^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end

            unless METHOD_NAMES.include?(%{snippet})
                   ^^^^^^^^^^^^^^^^^^^^^^^{snippet}^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end
          end
        RUBY
      end

      it 'flags condition using `Array#include?` with local assignment' do
        expect_offense(<<~RUBY, snippet: snippet)
          def on_send(node)
            name = %{snippet}
            return if METHOD_NAMES.include?(name)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
            return unless METHOD_NAMES.include?(name)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]

            name2 = %{snippet}
            if METHOD_NAMES.include?(name2)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end

            unless METHOD_NAMES.include?(name2)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Define constant `RESTRICT_ON_SEND`[...]
              add_offense(node)
            end
          end
        RUBY
      end

      it 'ignores condition using `Array#include?` with `else` branches' do
        expect_no_offenses(<<~RUBY)
          def on_send(node)
            if METHOD_NAMES.include?(#{snippet})
              add_offense(node)
            else
              something_else
            end

            unless METHOD_NAMES.include?(%{snippet})
              add_offense(node)
            else
              something_else
            end

            name = #{snippet}
            if METHOD_NAMES.include?(name)
              add_offense(node)
            else
              something_else
            end

            name2 = #{snippet}
            unless METHOD_NAMES.include?(name2)
              add_offense(node)
            else
              something_else
            end
          end
        RUBY
      end

      it 'ignores any condition if `RESTRICT_ON_SEND` is set' do
        expect_no_offenses(<<~RUBY)
          FOO = 1
          RESTRICT_ON_SEND = %i[some_method_name].freeze
          BAR = 2

          def on_send(node)
            return unless #{snippet} == :some_method_name

            if #{snippet} == :some_method_name
              add_offense(node)
            end

            name = #{snippet}
            return if METHOD_NAMES.include?(name)
          end
        RUBY
      end

      it 'ignores any if method is not `on_send`' do
        expect_no_offenses(<<~RUBY)
          def on_csend(node)
            return unless #{snippet} == :some_method_name

            if #{snippet} == :some_method_name
              add_offense(node)
            end

            name = #{snippet}
            return if METHOD_NAMES.include?(name)
          end
        RUBY
      end
    end
  end

  it_behaves_like 'checking for missing RESTRICT_ON_SEND', 'method_name(node)'
  it_behaves_like 'checking for missing RESTRICT_ON_SEND', 'node.children[1]'
end
