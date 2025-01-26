# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/polymorphic_associations'

RSpec.describe Rubocop::Cop::PolymorphicAssociations do
  it 'registers an offense when polymorphic: true is used' do
    expect_offense(<<~RUBY)
      belongs_to :foo, polymorphic: true
                       ^^^^^^^^^^^^^^^^^ Do not use polymorphic associations, use separate tables instead
      belongs_to :foo, bar: true, polymorphic: true
                                  ^^^^^^^^^^^^^^^^^ Do not use polymorphic associations, use separate tables instead
      belongs_to :foo, polymorphic: true, bar: true
                       ^^^^^^^^^^^^^^^^^ Do not use polymorphic associations, use separate tables instead

      object.belongs_to :foo, polymorphic: true
                              ^^^^^^^^^^^^^^^^^ Do not use polymorphic associations, use separate tables instead
    RUBY
  end

  it 'does not flag unsupported methods' do
    expect_no_offenses(<<~RUBY)
      something_else :foo, bar: true, polymorphic: true
    RUBY
  end
end
