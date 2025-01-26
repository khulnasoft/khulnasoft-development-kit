# frozen_string_literal: true

# rubocop:disable Lint/InterpolationCheck

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/tailwind/string_interpolation'

RSpec.describe Rubocop::Cop::Tailwind::StringInterpolation do
  describe 'interpolated CSS utils detection' do
    context 'when there are interpolated utils' do
      where(:code) do
        [
          '"gl-bg-#{palette}-#{variant}"',
          '"gl-#{display} gl-border"',
          '"gl-border gl-#{display}"',
          '"gl-w-1/#{denominator}"'
        ]
      end

      with_them do
        it 'registers an offense' do
          expect_offense(<<~'RUBY', code: code)
            %{code}
            ^{code} String interpolations in CSS utility class names are forbidden.[...]
          RUBY
        end
      end
    end

    context 'when there are no interpolated utils' do
      where(:code) do
        [
          '"gl-bg-red-800"',
          '"#{foo} gl-border"',
          '"gl-border #{foo}"',
          '"#{foo} gl-border gl-"',
          '"foo-#{foo}-gl-border-#{bar}"'
        ]
      end

      with_them do
        it 'does not register an offense' do
          expect_no_offenses(code)
        end
      end
    end
  end
end

# rubocop:enable Lint/InterpolationCheck
