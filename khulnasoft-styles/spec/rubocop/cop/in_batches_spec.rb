# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/in_batches'

RSpec.describe Rubocop::Cop::InBatches do
  it 'registers an offense when in_batches is used' do
    expect_offense(<<~RUBY)
      foo.in_batches do; end
          ^^^^^^^^^^ Do not use `in_batches`, use `each_batch` from the EachBatch module instead
    RUBY
  end

  it 'does not flag unsupported methods' do
    expect_no_offenses(<<~RUBY)
      foo.each_batches do; end
    RUBY
  end
end
