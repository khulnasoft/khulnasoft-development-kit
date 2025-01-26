# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/khulnasoft_security/json_serialization'

RSpec.describe RuboCop::Cop::KhulnasoftSecurity::JsonSerialization do
  def message_for(method)
    format("Don't use `%s` without specifying `only`", method)
  end

  shared_examples 'an upstanding constable' do |method|
    it "ignores calls except `#{method}`" do
      expect_no_offenses('render json: foo')
    end

    context "with `#{method}` and without options" do
      it 'does nothing when sent to nil receiver' do
        expect_no_offenses(method.to_s)
      end

      it 'does nothing when sent to a Hash' do
        expect_no_offenses("{}.#{method}")
      end

      it 'does nothing when sent to a Serializer instance' do
        aggregate_failures do
          expect_no_offenses(<<~RUBY)
            IssueSerializer.new.represent(issuable).#{method}
          RUBY

          expect_no_offenses(<<~RUBY)
            MergeRequestSerializer
              .new(current_user: current_user, project: issuable.project)
              .represent(issuable)
              .#{method}
          RUBY
        end
      end

      it 'adds an offense when sent to any other receiver' do
        expect_offense(<<-'RUBY', method: method, message: message_for(method))
          foo.%{method}
              ^{method} %{message}
        RUBY
      end
    end

    context "with `#{method}` and with options" do
      it 'does nothing when provided `only`' do
        expect_no_offenses(<<~RUBY)
          render json: @issue.#{method}(only: [:name, :username])
        RUBY
      end

      it 'does nothing when provided `only` and `methods`' do
        expect_no_offenses(<<~RUBY)
          render json: @issue.#{method}(
            only: [:name, :username],
            methods: [:avatar_url]
          )
        RUBY
      end

      it 'adds an offense to `include`d attributes without `only` option' do
        expect_offense(<<~RUBY)
          render json: @issue.#{method}(
            include: {
              milestone: {},
              ^^^^^^^^^^^^^ #{message_for(method)}
              assignee: { methods: :avatar_url },
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message_for(method)}
              author: { only: %i[foo bar] },
            }
          )
        RUBY
      end

      it 'handles a top-level `only` with child `include`s' do
        expect_offense(<<~RUBY)
          render json: @issue.#{method}(
            only: [:foo, :bar],
            include: {
              assignee: { methods: :avatar_url },
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message_for(method)}
              author: { only: %i[foo bar] }
            }
          )
        RUBY
      end

      it 'adds an offense for `include: [...]`' do
        # Spacing is off on the highlight due to interpolation
        expect_offense(<<~RUBY)
          render json: @issue.#{method}(include: %i[foo bar baz])
                                      ^^^^^^^^^^^^^^^^^^^^^^^^ #{message_for(method)}
        RUBY
      end

      it 'adds an offense for `except`' do
        # Spacing is off on the highlight due to interpolation
        expect_offense(<<~RUBY)
          render json: @issue.#{method}(except: [:private_token])
                                      ^^^^^^^^^^^^^^^^^^^^^^^^ #{message_for(method)}
        RUBY
      end
    end
  end

  include_examples 'an upstanding constable', :to_json
  include_examples 'an upstanding constable', :as_json
end
