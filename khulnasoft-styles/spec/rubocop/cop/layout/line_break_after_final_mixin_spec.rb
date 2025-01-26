# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/layout/line_break_after_final_mixin'

RSpec.describe RuboCop::Cop::Layout::LineBreakAfterFinalMixin do
  context "when there is no mixin" do
    it "does not raise an offense" do
      expect_no_offenses(<<~RUBY)
        class Hello
          def world
          end
        end
      RUBY
    end
  end

  %w[include extend prepend].each do |mixin|
    context "when there are two #{mixin}s" do
      it "raises an offense" do
        expect_offense(<<~RUBY, mixin: mixin)
          class Hello
            %{mixin} Something1
            %{mixin} Something2
            ^{mixin}^^^^^^^^^^^ Add an empty line after the last `%{mixin}`.
            def world
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Hello
            #{mixin} Something1
            #{mixin} Something2

            def world
            end
          end
        RUBY
      end
    end

    context "when there is an empty line after the last #{mixin}" do
      it "does not raise an offense" do
        expect_no_offenses(<<~RUBY)
          class Hello
            #{mixin} Something1
            #{mixin} Something2

            def world
            end
          end
        RUBY
      end
    end

    context "when the next line is an `end` line" do
      it "does not raise an offense" do
        expect_no_offenses(<<~RUBY)
          class Hello
            #{mixin} Something1
            #{mixin} Something2
          end
        RUBY
      end
    end
  end

  context "when there are mixed of includes, extends, and prepends" do
    context "when there is no empty line after the last prepend" do
      it "raises an offense" do
        expect_offense(<<~RUBY)
          class Hello
            include Something1
            extend Something2
            prepend Something3
            ^^^^^^^^^^^^^^^^^^ Add an empty line after the last `prepend`.
            def world
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Hello
            include Something1
            extend Something2
            prepend Something3

            def world
            end
          end
        RUBY
      end
    end

    context "when there is an empty line after the last prepend" do
      it "does not raise an offense" do
        expect_no_offenses(<<~RUBY)
          class Hello
            include Something1
            extend Something2
            prepend Something3

            def world
            end
          end
        RUBY
      end
    end
  end

  context "when a normal method has one of the mixin names" do
    it "does not raise an offense" do
      expect_no_offenses(<<~RUBY)
        class Hello
          something.include("Hello") # `include` is just a method
          do_something_else
        end
      RUBY
    end
  end

  context "when mixins are called from `self`" do
    context "when there is no empty line after the last mixin" do
      it "raises an offense" do
        expect_offense(<<~RUBY)
          class Hello
            self.include Something1
            self.include Something2
            ^^^^^^^^^^^^^^^^^^^^^^^ Add an empty line after the last `include`.
            def world
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Hello
            self.include Something1
            self.include Something2

            def world
            end
          end
        RUBY
      end
    end

    context "when there is an empty line after the last mixin" do
      it "does not raise an offense" do
        expect_no_offenses(<<~RUBY)
          class Hello
            self.include Something1
            self.include Something2

            def world
            end
          end
        RUBY
      end
    end
  end

  context "when the next line is not an `end` line" do
    it "raises an offense" do
      expect_offense(<<~RUBY)
        class Hello
          include Something1
          include Something2
          ^^^^^^^^^^^^^^^^^^ Add an empty line after the last `include`.
          endpoint_call(hello)

          def world
          end
        end
      RUBY
    end
  end

  context "when there is a comment after the last mixin" do
    it "raises an offense" do
      expect_offense(<<~RUBY)
        class Hello
          include Something1
          include Something2
          ^^^^^^^^^^^^^^^^^^ Add an empty line after the last `include`.
          # comment
          def world
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Hello
          include Something1
          include Something2

          # comment
          def world
          end
        end
      RUBY
    end
  end
end
