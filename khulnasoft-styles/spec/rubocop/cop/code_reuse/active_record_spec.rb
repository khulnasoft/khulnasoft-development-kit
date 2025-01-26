# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/code_reuse/active_record'

RSpec.describe Rubocop::Cop::CodeReuse::ActiveRecord do
  it 'flags the use of "where" without any arguments' do
    expect_offense(<<~RUBY)
    def foo
      User.where
           ^^^^^ This method can only be used inside an ActiveRecord model: https://docs.khulnasoft.com/ee/development/reusing_abstractions.html
    end
    RUBY
  end

  it 'flags the use of "where" with arguments' do
    expect_offense(<<~RUBY)
    def foo
      User.where(id: 10)
           ^^^^^ This method can only be used inside an ActiveRecord model: https://docs.khulnasoft.com/ee/development/reusing_abstractions.html
    end
    RUBY
  end

  it 'does not flag the use of "group" without any arguments' do
    expect_no_offenses(<<~RUBY)
    def foo
      project.group
    end
    RUBY
  end

  it 'flags the use of "group" with arguments' do
    expect_offense(<<~RUBY)
    def foo
      project.group(:name)
              ^^^^^ This method can only be used inside an ActiveRecord model: https://docs.khulnasoft.com/ee/development/reusing_abstractions.html
    end
    RUBY
  end
end
