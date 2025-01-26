# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/tailwind/max_width_media_queries'

RSpec.describe Rubocop::Cop::Tailwind::MaxWidthMediaQueries do
  describe 'max-width media query CSS utils detection' do
    message = 'Do not use max-width media query utility classes unless absolutely necessary. ' \
      'Use min-width media query utility classes instead.'

    # rubocop:disable Tailwind/MaxWidthMediaQueries

    it 'registers offense for string' do
      expect_offense(<<~RUBY, message: message)
        "gl-mt-5 max-md:gl-mt-3"
        ^^^^^^^^^^^^^^^^^^^^^^^^ %{message}
      RUBY
    end

    it 'registers offense for array' do
      expect_offense(<<~RUBY, message: message)
        ["gl-mt-5", "max-md:gl-mt-3"]
                    ^^^^^^^^^^^^^^^^ %{message}
      RUBY
    end

    it 'registers offense for hash' do
      expect_offense(<<~RUBY, message: message)
        { "gl-mt-5" => true, "max-md:gl-mt-3" => true }
                             ^^^^^^^^^^^^^^^^ %{message}
      RUBY
    end

    it 'registers offense for HAML' do
      expect_offense(<<~RUBY, message: message)
        '.gl-mt-5.max-md:gl-mt-3'
        ^^^^^^^^^^^^^^^^^^^^^^^^^ %{message}
      RUBY
    end

    # rubocop:enable Tailwind/MaxWidthMediaQueries

    context 'when there are no max-width media query utils' do
      where(:code) do
        [
          '"gl-mt-3 md:gl-mt-5"',
          '["gl-mt-3", "md:gl-mt-5"]',
          '{ "gl-mt-3" => true, "md:gl-mt-5" => true }',
          '".gl-mt-3.md:gl-mt-5"'
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
