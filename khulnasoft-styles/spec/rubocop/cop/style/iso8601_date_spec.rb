# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/rubocop/cop/style/iso8601_date'

RSpec.describe RuboCop::Cop::Style::Iso8601Date do
  it 'autocorrects simple use of strftime' do
    expect_offense(<<~RUBY)
      DateTime.now.strftime('%Y-%m-%d')
                   ^^^^^^^^^^^^^^^^^^^^ Use `iso8601` instead of `strftime("%Y-%m-%d")`.
    RUBY

    expect_correction(<<~RUBY)
      DateTime.now.to_date.iso8601
    RUBY
  end

  it 'autocorrects use of strftime in long chain' do
    expect_offense(<<~RUBY)
      60.days.from_now.strftime('%Y-%m-%d')
                       ^^^^^^^^^^^^^^^^^^^^ Use `iso8601` instead of `strftime("%Y-%m-%d")`.
    RUBY

    expect_correction(<<~RUBY)
      60.days.from_now.to_date.iso8601
    RUBY
  end

  it 'does not flag the use strftime in general' do
    expect_no_offenses("DateTime.now.strftime('%Y')")
  end
end
