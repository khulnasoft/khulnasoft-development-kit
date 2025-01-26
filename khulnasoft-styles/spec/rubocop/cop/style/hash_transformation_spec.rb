# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/style/hash_transformation'

RSpec.describe Rubocop::Cop::Style::HashTransformation do
  shared_examples 'hash transformation' do |method_name|
    it "registers an offense for `#{method_name} { ... }.to_h` and corrects", :aggregate_failures do
      expect_offense(<<~RUBY, method_name: method_name)
        hash.%{method_name} { |k, v| [v, k] }.to_h
             ^{method_name}^^^^^^^^^^^^^^^^^^^^^^^ Use `to_h { ... }` instead of `%{method_name} { ... }.to_h`.
      RUBY

      expect_correction(<<~RUBY)
        hash.to_h { |k, v| [v, k] }
      RUBY
    end

    it "registers an offense for `each_with_index.#{method_name} { ... }.to_h` and corrects", :aggregate_failures do
      expect_offense(<<~RUBY, method_name: method_name)
        array.each_with_index.%{method_name} { |el, i| [i, el] }.to_h
                              ^{method_name}^^^^^^^^^^^^^^^^^^^^^^^^^ Use `to_h { ... }` instead of `%{method_name} { ... }.to_h`.
      RUBY

      expect_correction(<<~RUBY)
        array.each_with_index.to_h { |el, i| [i, el] }
      RUBY
    end

    it "does not register an offense for `#{method_name} { ... }.to_h { ... }`" do
      expect_no_offenses(<<~RUBY)
        hash.#{method_name} { |k, v| [v, k] }.to_h { |k, v| [v, k] }
      RUBY
    end

    it "registers an offense for `Hash[#{method_name} { ... }]` and corrects", :aggregate_failures do
      expect_offense(<<~RUBY, method_name: method_name)
        Hash[hash.%{method_name} { |k, v| [v, k] }]
        ^{method_name}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `to_h { ... }` instead of `Hash[%{method_name} { ... }]`.
      RUBY

      expect_correction(<<~RUBY)
        hash.to_h { |k, v| [v, k] }
      RUBY
    end

    it "registers an offense for `Hash[each_with_index.#{method_name} { ... }]` and corrects", :aggregate_failures do
      expect_offense(<<~RUBY, method_name: method_name)
        Hash[array.each_with_index.#{method_name} { |el, i| [i, el] }]
        ^{method_name}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `to_h { ... }` instead of `Hash[%{method_name} { ... }]`.
      RUBY

      expect_correction(<<~RUBY)
        array.each_with_index.to_h { |el, i| [i, el] }
      RUBY
    end
  end

  it_behaves_like 'hash transformation', 'map'
  it_behaves_like 'hash transformation', 'collect'

  it 'does not register an offense for `to_h { ... }`' do
    expect_no_offenses(<<~RUBY)
      hash.to_h { |k, v| [v, k] }
    RUBY
  end
end
