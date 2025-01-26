# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/custom_error_class'

RSpec.describe Rubocop::Cop::CustomErrorClass do
  context 'when a class has a body' do
    it 'does nothing' do
      expect_no_offenses(<<~RUBY)
        class CustomError < StandardError; def foo; end; end
      RUBY
    end
  end

  context 'when a class has no explicit superclass' do
    it 'does nothing' do
      expect_no_offenses(<<~RUBY)
        class CustomError; end
      RUBY
    end
  end

  context 'when a class has a superclass that does not end in Error' do
    it 'does nothing' do
      expect_no_offenses(<<~RUBY)
        class CustomError < BasicObject; end
      RUBY
    end
  end

  context 'when a class is empty and inherits from a class ending in Error' do
    context 'when the class is on a single line' do
      it 'registers an offense and corrects', :aggregate_failures do
        expect_offense(<<-RUBY)
          module Foo
            class CustomError < Bar::Baz::BaseError; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Class.new(SuperClass)` to define an empty custom error class.
          end
        RUBY

        expect_correction(<<-RUBY)
          module Foo
            CustomError = Class.new(Bar::Baz::BaseError)
          end
        RUBY
      end
    end

    context 'when the class is on multiple lines' do
      it 'registers an offense', :aggregate_failures do
        expect_offense(<<-RUBY)
          module Foo
            class CustomError < Bar::Baz::BaseError
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Class.new(SuperClass)` to define an empty custom error class.
            end
          end
        RUBY

        expect_correction(<<-RUBY)
          module Foo
            CustomError = Class.new(Bar::Baz::BaseError)
          end
        RUBY
      end
    end
  end
end
