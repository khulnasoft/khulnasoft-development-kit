# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/single_line_hook'

RSpec.describe Rubocop::Cop::RSpec::SingleLineHook do
  it 'ignores non-test file' do
    expect_no_offenses(<<-RUBY, 'foo.rb')
      class Foo
        before { do_something }
      end
    RUBY
  end

  it 'registers an offense for a single-line `before` block' do
    expect_offense(<<-RUBY)
      describe 'foo' do
        before { do_something }
        ^^^^^^^^^^^^^^^^^^^^^^^ Don't use single-line hook blocks.
      end
    RUBY
  end

  it 'registers an offense for a single-line `after` block' do
    expect_offense(<<-RUBY)
      describe 'foo' do
        after(:each) { undo_something }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use single-line hook blocks.
      end
    RUBY
  end

  it 'registers an offense for a single-line `around` block' do
    expect_offense(<<-RUBY)
      describe 'foo' do
        around { |ex| do_something_else }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use single-line hook blocks.
      end
    RUBY
  end

  it 'ignores a multi-line `before` block' do
    expect_no_offenses(<<-RUBY)
      describe 'foo' do
        before do
          do_something
        end
      end
    RUBY
  end

  it 'ignores a multi-line `after` block' do
    expect_no_offenses(<<-RUBY)
      describe 'foo' do
        after(:each) do
          do_something
        end
      end
    RUBY
  end

  it 'ignores a multi-line `around` block' do
    expect_no_offenses(<<-RUBY)
      describe 'foo' do
        around do |ex|
          do_something
        end
      end
    RUBY
  end
end
