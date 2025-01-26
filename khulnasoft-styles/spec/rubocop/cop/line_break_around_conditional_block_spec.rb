# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/line_break_around_conditional_block'

RSpec.describe Rubocop::Cop::LineBreakAroundConditionalBlock, type: :rubocop do
  def offense_msg(conditional)
    "^^^^^^^^^^#{'^' * conditional.length} Add a line break around conditional blocks"
  end

  shared_examples 'examples with conditional' do |conditional|
    it "flags violation for #{conditional} without line break before" do
      expect_offense(<<~RUBY)
          do_something
          #{conditional} condition
          #{offense_msg(conditional)}
            do_something_more
          end
      RUBY

      expect_correction(<<~RUBY)
          do_something

          #{conditional} condition
            do_something_more
          end
      RUBY
    end

    it "flags violation for #{conditional} without line break after" do
      expect_offense(<<~RUBY)
          #{conditional} condition
          #{offense_msg(conditional)}
            do_something
          end
          do_something_more
      RUBY

      expect_correction(<<~RUBY)
          #{conditional} condition
            do_something
          end

          do_something_more
      RUBY
    end

    it "doesn't flag violation for #{conditional} with line break before and after" do
      expect_no_offenses(<<~RUBY)
          #{conditional} condition
            do_something
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a method definition" do
      expect_no_offenses(<<~RUBY)
          def a_method
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a method definition with multiline argument definition" do
      expect_no_offenses(<<~RUBY)
          def a_method(
                multiline: :arg
              )
            #{conditional} condition
              do_something
            end
          end

          def a_method(
                multiline: :arg) # OK
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a class definition" do
      expect_no_offenses(<<~RUBY)
          class Foo
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a module definition" do
      expect_no_offenses(<<~RUBY)
          module Foo
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a begin definition" do
      expect_no_offenses(<<~RUBY)
          begin
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by an assign/begin definition" do
      expect_no_offenses(<<~RUBY)
          @project ||= begin
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a block definition" do
      expect_no_offenses(<<~RUBY)
          on_block(param_a) do |item|
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a block definition with a comment" do
      expect_no_offenses(<<~RUBY)
          on_block(param_a) do |item| # a short comment
            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a block definition using brackets" do
      expect_no_offenses(<<~RUBY)
          on_block(param_a) { |item|
            #{conditional} condition
              do_something
            end
          }
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a comment" do
      expect_no_offenses(<<~RUBY)
          # a short comment
          #{conditional} condition
            do_something
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by an assignment" do
      expect_no_offenses(<<~RUBY)
          foo =
            #{conditional} condition
              do_something
            else
              do_something_more
            end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a multiline comment" do
      expect_no_offenses(<<~RUBY)
          =begin
          a multiline comment
          =end
          #{conditional} condition
            do_something
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by another conditional" do
      expect_no_offenses(<<~RUBY)
          #{conditional} condition_a
            #{conditional} condition_b
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by an else" do
      expect_no_offenses(<<~RUBY)
           if condition_a
             do_something
           else
             #{conditional} condition_b
               do_something_extra
             end
           end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by an elsif" do
      expect_no_offenses(<<~RUBY)
           if condition_a
             do_something
           elsif condition_b
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by an ensure" do
      expect_no_offenses(<<~RUBY)
           def a_method
           ensure
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a when" do
      expect_no_offenses(<<~RUBY)
           case field
           when value
             #{conditional} condition_c
               do_something_extra
             end
           end
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by a comment" do
      expect_no_offenses(<<~RUBY)
          #{conditional} condition
            do_something
          end
          # a short comment
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by an end" do
      expect_no_offenses(<<~RUBY)
          class Foo

            #{conditional} condition
              do_something
            end
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by an else" do
      expect_no_offenses(<<~RUBY)
          #{conditional} condition_a
            #{conditional} condition_b
              do_something
            end
          else
            do_something_extra
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by a when" do
      expect_no_offenses(<<~RUBY)
          case
          when condition_a
            #{conditional} condition_b
              do_something
            end
          when condition_c
            do_something_extra
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by an elsif" do
      expect_no_offenses(<<~RUBY)
          if condition_a
            #{conditional} condition_b
              do_something
            end
          elsif condition_c
            do_something_extra
          end
      RUBY
    end

    it "doesn't flag violation for #{conditional} preceded by a rescue" do
      expect_no_offenses(<<~RUBY)
        def a_method
          do_something
        rescue
          #{conditional} condition
            do_something
          end
        end
      RUBY
    end

    it "doesn't flag violation for #{conditional} followed by a rescue" do
      expect_no_offenses(<<~RUBY)
            def a_method
              #{conditional} condition
                do_something
              end
              rescue
                do_something_extra
            end
      RUBY
    end

    it "autocorrects #{conditional} without line break before and after" do
      expect_offense(<<~RUBY)
          do_something
          #{conditional} condition
          #{offense_msg(conditional)}
            do_something_more
          end
          do_something_extra
      RUBY

      expect_correction(<<~RUBY)
          do_something

          #{conditional} condition
            do_something_more
          end

          do_something_extra
      RUBY
    end
  end

  %w[if unless].each do |example|
    it_behaves_like 'examples with conditional', example
  end

  it "doesn't flag violation for if with elsif" do
    expect_no_offenses(<<~RUBY)
          if condition
            do_something
          elsif another_condition
            do_something_more
          end
    RUBY
  end
end
