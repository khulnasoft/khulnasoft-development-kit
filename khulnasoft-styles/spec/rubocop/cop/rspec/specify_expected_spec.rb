# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/specify_expected'

RSpec.describe Rubocop::Cop::RSpec::SpecifyExpected do
  it 'registers offenses where `specify` is used with `is_expected`' do
    expect_offense(<<~RUBY)
      specify { is_expected.to eq(true) }
      ^^^^^^^ Prefer using `it` when used with `is_expected`.

      specify do
      ^^^^^^^ Prefer using `it` when used with `is_expected`.
        is_expected.to eq(true)
      end
    RUBY

    expect_correction(<<~RUBY)
      it { is_expected.to eq(true) }

      it do
        is_expected.to eq(true)
      end
    RUBY
  end

  it 'does not register offenses when `is_expected` is missing in `specify`' do
    expect_no_offenses(<<~RUBY)
      specify { expect(foo).to eq(true) }

      specify do
        expect(foo).to eq(true)
      end
    RUBY
  end
end
