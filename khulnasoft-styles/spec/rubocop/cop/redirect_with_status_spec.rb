# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/redirect_with_status'

RSpec.describe Rubocop::Cop::RedirectWithStatus do
  shared_examples 'checking status in redirect_to' do |method|
    it 'registers an offense when a "destroy" action uses "redirect_to" without "status"' do
      expect_offense(<<~RUBY)
        def #{method}
          redirect_to alert: 'Oh no!'
          ^^^^^^^^^^^ Do not use "redirect_to" without "status" in "#{method}" action.

          redirect_to root_path, alert: 'Oh no!'
          ^^^^^^^^^^^ Do not use "redirect_to" without "status" in "#{method}" action.
        end
      RUBY
    end

    it %(does not register an offense when a "#{method}" action uses "redirect_to" with "status") do
      expect_no_offenses(<<~RUBY)
        def #{method}
          redirect_to status: 302
          redirect_to root_path, status: 302
          redirect_to root_path, status: 302, alert: 'Oh no!'
          redirect_to root_path, alert: 'Oh no!', status: 302
        end
      RUBY
    end
  end

  it_behaves_like 'checking status in redirect_to', 'destroy'
  it_behaves_like 'checking status in redirect_to', 'destroy_all'
end
