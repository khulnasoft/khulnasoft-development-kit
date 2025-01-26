# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/khulnasoft_security/public_send'

RSpec.describe RuboCop::Cop::KhulnasoftSecurity::PublicSend do
  shared_examples 'an upstanding constable' do |method|
    it "adds an offense for `#{method}`" do
      expect_offense(<<~RUBY, method: method)
        basic.%{method}(:bar)
              ^{method} Avoid using `%{method}`.
      RUBY
    end

    it "adds an offense for `#{method}` with arguments" do
      expect_offense(<<~RUBY, method: method)
        args.%{method}(:bar, baz: true)
             ^{method} Avoid using `%{method}`.
      RUBY
    end

    it "adds offense for `#{method}` on `nil` receiver" do
      expect_offense(<<~RUBY, method: method)
        %{method}(:foo)
        ^{method} Avoid using `%{method}`.
      RUBY
    end

    it "adds an offense for `#{method}` when using a safe accessor" do
      expect_offense(<<~RUBY, method: method)
        basic&.%{method}(:bar)
               ^{method} Avoid using `%{method}`.
      RUBY
    end

    it "ignores `#{method}` with no argument" do
      expect_no_offenses("foo.#{method}")
    end
  end

  include_examples 'an upstanding constable', :send
  include_examples 'an upstanding constable', :public_send
  include_examples 'an upstanding constable', :__send__
end
