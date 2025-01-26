# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/useless_dynamic_definition'

RSpec.describe Rubocop::Cop::RSpec::UselessDynamicDefinition, :rspec_cop_spec do
  shared_examples 'dynamic definition check' do |each_method|
    context 'with lets' do
      before do
        other_cops.tap do |config|
          config.dig('RSpec', 'Language', 'Helpers').push('custom_let')
        end
      end

      where(:code) do
        [
          'let(:foo) {}',
          'let!(:foo) {}',
          'custom_let(:foo) {}'
        ]
      end

      with_them do
        it 'flags dynamic definition' do
          expect_offense(<<~RUBY, each_method: each_method)
            context 'foo' do
              some = code
              collection.%{each_method} do |bool|
                         ^{each_method} Avoid useless dynamic definitions without `context`.
                #{code}
              end
            end
          RUBY
        end
      end
    end

    context 'with hooks' do
      before do
        other_cops.tap do |config|
          config.dig('RSpec', 'Language', 'Hooks').push('custom_before')
        end
      end

      where(:code) do
        [
          'before {}',
          'after(:each) {}',
          'around {}',
          'custom_before {}'
        ]
      end

      with_them do
        it 'flags dynamic definition' do
          expect_offense(<<~RUBY, each_method: each_method)
            context 'foo' do
              some = code
              collection.%{each_method} do |bool|
                         ^{each_method} Avoid useless dynamic definitions without `context`.
                #{code}
              end
            end
          RUBY
        end
      end
    end

    context 'with scope' do
      before do
        other_cops.tap do |config|
          config.dig('RSpec', 'Language', 'Examples', 'Regular').push('custom_it')
          config.dig('RSpec', 'Language', 'ExampleGroups', 'Regular').push('custom_describe')
        end
      end

      where(:scope) do
        %i[context it describe shared_examples shared_context
          custom_it custom_describe]
      end

      with_them do
        it 'does not flag with context' do
          expect_no_offenses(<<~RUBY)
            context 'foo' do
              collection.#{each_method} do |bool|
                #{scope} bool do
                  before {}
                end
              end
            end
          RUBY
        end

        it 'does not flag with outer context' do
          expect_no_offenses(<<~RUBY)
            context 'foo' do
              before {}

              collection.#{each_method} do |bool|
                #{scope} 'works' do
                end
              end
            end
          RUBY
        end
      end
    end
  end

  it_behaves_like 'dynamic definition check', 'each'
  it_behaves_like 'dynamic definition check', 'each_key'
  it_behaves_like 'dynamic definition check', 'each_value'
end
