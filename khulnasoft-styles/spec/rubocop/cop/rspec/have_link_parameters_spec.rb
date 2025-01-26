# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/have_link_parameters'

RSpec.describe Rubocop::Cop::RSpec::HaveLinkParameters do
  it 'ignores have_link with a single parameter' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_link('Link')
    RUBY
  end

  it 'ignores have_link with used parameters' do
    expect_no_offenses(<<~RUBY)
      expect(page).to have_link('Link', href: 'https://example.com/')
    RUBY
  end

  it 'registers an offense for have_link with unused parameters' do
    expect_offense(<<~RUBY)
      expect(page).to have_link('Link', 'https://example.com/')
                                        ^^^^^^^^^^^^^^^^^^^^^^ The second argument to `have_link` should be a Hash.
    RUBY
  end
end
