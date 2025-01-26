# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/active_record_serialize'

RSpec.describe Rubocop::Cop::ActiveRecordSerialize do
  it 'registers an offense when serialize is used' do
    expect_offense(<<~RUBY)
      serialize :foo
      ^^^^^^^^^ Do not store serialized data in the database, use separate columns and/or tables instead
    RUBY
  end

  it 'does not flag unsupported methods' do
    expect_no_offenses(<<~RUBY)
      something_else :foo

      object.serialize
    RUBY
  end
end
