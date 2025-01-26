# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/internal_affairs/cop_description_with_example'

RSpec.describe Rubocop::Cop::InternalAffairs::CopDescriptionWithExample do
  # Ensure parent class behaviour is still intact
  context 'when the description starts with `This cop ...`' do
    it 'registers an offense and corrects if using just a verb' do
      expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # This cop checks some offenses...
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Description should be started with `Checks` instead of `This cop ...`.
              #
              # @example
              #   # Good
              #   array.any?
              #
              #   # Bad
              #   !array.empty?
              class Foo < Base
              end
            end
          end
        end
      RUBY

      allow_any_instance_of(described_class).to receive(:relevant_file?).and_return(true)

      expect_correction(<<~RUBY)
        module RuboCop
          module Cop
            module Lint
              # Checks some offenses...
              #
              # @example
              #   # Good
              #   array.any?
              #
              #   # Bad
              #   !array.empty?
              class Foo < Base
              end
            end
          end
        end
      RUBY
    end
  end

  it 'does not register if the description includes an example' do
    expect_no_offenses(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
              # @example
              #   # good
              #   array.any?
              #
              #   # bad
              #   !array.empty?
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does not register if the description includes a configuration specific example' do
    expect_no_offenses(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
              # @example Option1: true
              #   # good
              #   array.any?
              #
              #   # bad
              #   !array.empty?
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does not register if the description includes an example with "# good (extra content)"' do
    expect_no_offenses(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
              # @example
              #   # good (extra context)
              #   array.any?
              #
              #   # bad (extra context)
              #   array.size == 0
              #
              #   # bad (extra context)
              #   !array.empty?
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does register if the description includes an example with "# goody" instead of "# good"' do
    expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
                ^^^^^^^^^^^^^^^^^^^^^ Description should include good and bad examples
              # @example
              #   # goody
              #   array.any?
              #
              #   # bad
              #   !array.empty?
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does register if the description does not include an example' do
    expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
                ^^^^^^^^^^^^^^^^^^^^^ Description should include good and bad examples
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does register if the description includes an example without good or bad examples' do
    expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
                ^^^^^^^^^^^^^^^^^^^^^ Description should include good and bad examples
              # @example
              #   array.any?
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  it 'does register if the description includes good and bad with the example coming after' do
    expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              # Either foo or bar ...
                ^^^^^^^^^^^^^^^^^^^^^ Description should include good and bad examples
              #   # good
              #   array.any?
              #
              #   # bad
              #   !array.empty?
              # @example
              # ...
              class Foo < Base
              end
            end
          end
        end
    RUBY
  end

  context 'when there is no description comment' do
    it 'registers an offense' do
      expect_offense(<<~RUBY, 'lib/rubocop/cop/internal_affairs/cop_description_with_example.rb')
        module RuboCop
          module Cop
            module Lint
              class Foo < Base
              ^^^^^^^^^^^^^^^^ Must include a description
              end
            end
          end
        end
      RUBY
    end
  end
end
