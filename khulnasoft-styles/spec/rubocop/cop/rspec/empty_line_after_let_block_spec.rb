# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/empty_line_after_let_block'

RSpec.describe Rubocop::Cop::RSpec::EmptyLineAfterLetBlock do
  include_context 'mock console output'

  # Use default configuration to catch other `let_` variants.
  let(:other_cops) do
    { 'RSpec' => RuboCop::ConfigLoader.configuration_from_file('rubocop-rspec.yml')['RSpec'] }
  end

  it 'flags a missing empty line after `let` block' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        let(:something) do
        end
        ^^^ Add an empty line after `let` block.
        let(:another_thing) do
        end
      end
    RUBY

    expect_correction(<<-RUBY)
      RSpec.describe Foo do
        let(:something) do
        end

        let(:another_thing) do
        end
      end
    RUBY
  end

  it 'flags a missing empty line after `let!` block' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        let!(:something) do
        end
        ^^^ Add an empty line after `let!` block.
        let!(:another_thing) do
        end
      end
    RUBY

    expect_correction(<<-RUBY)
      RSpec.describe Foo do
        let!(:something) do
        end

        let!(:another_thing) do
        end
      end
    RUBY
  end

  it 'flags a missing empty line after `let_it_be` block' do
    expect_offense(<<-RUBY)
      RSpec.describe Foo do
        let_it_be(:something) do
        end
        ^^^ Add an empty line after `let_it_be` block.
        let_it_be(:another_thing) do
        end
      end
    RUBY

    expect_correction(<<-RUBY)
      RSpec.describe Foo do
        let_it_be(:something) do
        end

        let_it_be(:another_thing) do
        end
      end
    RUBY
  end

  it 'ignores one-line let before let blocks' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe Foo do
        let(:something) { 'something' }
        let(:another_thing) do
        end
      end
    RUBY
  end

  it 'flags mixed one-line and multi-line let' do
    expect_offense(<<-RUBY)
      RSpec.context 'foo' do
        let(:something) { 'something' }
        let(:something_else) { 'something else' }
        let(:another_thing) do
        end
        ^^^ Add an empty line after `let` block.
        let!(:one_more_thing) { 'one more thing' }
        let(:last_thing) { 'last thing' }
      end
    RUBY
  end
end
