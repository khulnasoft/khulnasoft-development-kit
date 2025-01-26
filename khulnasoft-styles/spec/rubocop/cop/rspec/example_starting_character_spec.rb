# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/example_starting_character'

RSpec.describe Rubocop::Cop::RSpec::ExampleStartingCharacter do
  it 'ignores non-example blocks' do
    expect_no_offenses('foo "Does something" do; end')
  end

  it 'finds capital letter at the beginning' do
    expect_offense(<<-RUBY)
      it 'Does something' do
          ^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-RUBY)
      it 'does something' do
      end
    RUBY
  end

  it 'finds a space at the beginning' do
    expect_offense(<<-'RUBY')
      it " does #{:stuff}" do
          ^^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-'RUBY')
      it "does #{:stuff}" do
      end
    RUBY
  end

  it 'finds a space at the end' do
    expect_offense(<<-'RUBY')
      it "does #{:stuff} " do
          ^^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-'RUBY')
      it "does #{:stuff}" do
      end
    RUBY
  end

  it 'finds multiple spaces at the beginning and end' do
    expect_offense(<<-'RUBY')
      it "   does #{:stuff}  " do
          ^^^^^^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-'RUBY')
      it "does #{:stuff}" do
      end
    RUBY
  end

  it 'finds space at the beginning with acronym' do
    expect_offense(<<-'RUBY')
      it ' URI does something' do
          ^^^^^^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-'RUBY')
      it 'URI does something' do
      end
    RUBY
  end

  it 'finds space at the end with acronym' do
    expect_offense(<<-'RUBY')
      it 'URI does something ' do
          ^^^^^^^^^^^^^^^^^^^ Only start words with lowercase alpha with no leading/trailing spaces when describing your tests.
      end
    RUBY

    expect_correction(<<-'RUBY')
      it 'URI does something' do
      end
    RUBY
  end

  it 'skips descriptions with alpha at the beginning' do
    expect_no_offenses(<<-RUBY)
      it 'does something' do
      end
    RUBY
  end

  it 'skips descriptions with acronym at the beginning' do
    expect_no_offenses(<<-RUBY)
      it 'URI does something' do
      end
    RUBY
  end

  it 'skips descriptions with acronym pluralized at the beginning' do
    expect_no_offenses(<<-RUBY)
      it 'URIs does something' do
      end
    RUBY
  end
end
