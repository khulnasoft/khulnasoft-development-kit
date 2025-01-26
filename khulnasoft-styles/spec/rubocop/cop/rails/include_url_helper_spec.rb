# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rails/include_url_helper'

RSpec.describe Rubocop::Cop::Rails::IncludeUrlHelper do
  it 'registers an offense when ActionView::Helpers::UrlHelper is included' do
    expect_offense(<<~RUBY)
      class Foo
        include ActionView::Helpers::UrlHelper
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid including `ActionView::Helpers::UrlHelper`.[...]
      end
    RUBY
  end

  it 'registers an offense when ::ActionView::Helpers::UrlHelper is included' do
    expect_offense(<<~RUBY)
      class Foo
        include ::ActionView::Helpers::UrlHelper
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid including `ActionView::Helpers::UrlHelper`.[...]
      end
    RUBY
  end

  it 'does not register an offence when Foo::ActionView::Helpers::UrlHelper is included' do
    expect_no_offenses(<<~RUBY)
      class Foo
        include Foo::ActionView::Helpers::UrlHelper
      end
    RUBY
  end

  it 'does not register an offence on some other code' do
    expect_no_offenses(<<~RUBY)
      class Foo
        include ActionView::Helpers::Something
      end
    RUBY
  end
end
