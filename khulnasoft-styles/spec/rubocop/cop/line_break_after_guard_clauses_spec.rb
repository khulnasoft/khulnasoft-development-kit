# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/line_break_after_guard_clauses'

RSpec.describe Rubocop::Cop::LineBreakAfterGuardClauses do
  shared_examples 'examples with guard clause' do |title|
    %w[if unless].each do |conditional|
      it "flags violation for #{title} #{conditional} without line breaks and correct" do
        code = "#{title} #{conditional} condition"

        expect_offense(<<~'RUBY', code: code)
          %{code}
          ^{code} Add a line break after guard clauses
          do_stuff
        RUBY

        expect_correction(<<~RUBY)
          #{code}

          do_stuff
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} with line break" do
        expect_no_offenses(<<~RUBY)
          #{title} #{conditional} condition

          do_stuff
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} on multiple lines without line break" do
        expect_no_offenses(<<~RUBY)
          #{conditional} condition
            #{title}
          end
          do_stuff
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by end keyword" do
        expect_no_offenses(<<~RUBY)
          def test
            #{title} #{conditional} condition
          end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by elsif keyword" do
        expect_no_offenses(<<~RUBY)
          if model
            #{title} #{conditional} condition
          elsif
            do_something
          end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by else keyword" do
        expect_no_offenses(<<~RUBY)
          if model
            #{title} #{conditional} condition
          else
            do_something
          end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by when keyword" do
        expect_no_offenses(<<~RUBY)
          case model
            when condition_a
              #{title} #{conditional} condition
            when condition_b
              do_something
            end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by rescue keyword" do
        expect_no_offenses(<<~RUBY)
          begin
            #{title} #{conditional} condition
          rescue StandardError
            do_something
          end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} without line breaks when followed by ensure keyword" do
        expect_no_offenses(<<~RUBY)
          def foo
            #{title} #{conditional} condition
          ensure
            do_something
          end
        RUBY
      end

      it "doesn't flag violation for #{title} #{conditional} w/o line breaks when followed by another guard clause" do
        expect_no_offenses(<<~RUBY)
          #{title} #{conditional} condition
          #{title} #{conditional} condition

          do_stuff
        RUBY
      end
    end
  end

  %w[return fail raise next break throw].each do |example|
    it_behaves_like 'examples with guard clause', example
  end
end
