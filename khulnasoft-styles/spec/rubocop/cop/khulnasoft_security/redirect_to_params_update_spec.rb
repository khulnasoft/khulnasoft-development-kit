# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/khulnasoft_security/redirect_to_params_update'

RSpec.describe RuboCop::Cop::KhulnasoftSecurity::RedirectToParamsUpdate do
  it 'does not flag correct use' do
    expect_no_offenses(<<~RUBY)
      redirect_to allowed(params)
      redirect_to(allowed(params))
    RUBY
  end

  it 'flags incorrect use' do
    expect_offense(<<~RUBY)
      redirect_to(params.update(action: 'main'))
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using `redirect_to(params.update(...))`. [...]
      redirect_to(params.merge(action: 'main'))
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid using `redirect_to(params.merge(...))`. [...]
    RUBY
  end
end
