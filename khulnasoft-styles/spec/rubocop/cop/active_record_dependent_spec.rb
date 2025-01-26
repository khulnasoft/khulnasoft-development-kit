# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/active_record_dependent'

RSpec.describe Rubocop::Cop::ActiveRecordDependent do
  it 'registers an offense when dependent: is used' do
    expect_offense(<<~RUBY)
      belongs_to :foo, dependent: :destroy
                       ^^^^^^^^^^^^^^^^^^^ Do not use `dependent:` to remove associated data, use foreign keys with cascading deletes instead.

      belongs_to :foo, dependent: :nullify, bar: true
                       ^^^^^^^^^^^^^^^^^^^ Do not use `dependent:` to remove associated data, use foreign keys with cascading deletes instead.

      belongs_to :foo, bar: true, dependent: :delete_all
                                  ^^^^^^^^^^^^^^^^^^^^^^ Do not use `dependent:` to remove associated data, use foreign keys with cascading deletes instead.
    RUBY
  end

  context 'when using dependent: :restrict_with_error' do
    it 'does not register an offense when :restrict_with_error is used' do
      expect_no_offenses(<<~RUBY)
        has_many :foo, dependent: :restrict_with_error
      RUBY
    end
  end

  it 'does not flag on unsupported methods' do
    expect_no_offenses(<<~RUBY)
      something_else :foo, dependent: :destroy
    RUBY
  end
end
