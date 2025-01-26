# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/internal_affairs/deprecate_cop_helper'

RSpec.describe Rubocop::Cop::InternalAffairs::DeprecateCopHelper do
  let(:msg) do
    'Do not use `CopHelper` or methods from it, use improved patterns described in https://www.rubydoc.info/gems/rubocop/RuboCop/RSpec/ExpectOffense'
  end

  context 'when used as a mixin' do
    def exception_node(mixin)
      "#{mixin} CopHelper"
    end

    where(mixin: %w[include extend prepend])

    with_them do
      it 'flags the use of CopHelper' do
        node = exception_node(mixin)

        expect_offense(<<~RUBY, node: node, msg: msg)
          %{node}
          ^{node} %{msg}
        RUBY
      end
    end
  end

  context 'when methods are used' do
    method_names = %w[
      inspect_source
      inspect_source_file
      parse_source
      autocorrect_source_file
      autocorrect_source
      _investigate
    ]

    where(method_name: method_names)

    with_them do
      it 'flags the use of CopHelper method' do
        expect_offense(<<~RUBY, node: method_name, msg: msg)
          %{node}
          ^{node} %{msg}
        RUBY
      end
    end
  end

  context 'when methods are used on the cop instance' do
    def exception_node(mixin)
      "cop.#{mixin}"
    end

    where(mixin: %w[highlights messages offenses])

    with_them do
      it 'flags the use of CopHelper methods' do
        node = exception_node(mixin)

        expect_offense(<<~RUBY, node: node, msg: msg)
          %{node}
          ^{node} %{msg}
        RUBY
      end
    end
  end
end
