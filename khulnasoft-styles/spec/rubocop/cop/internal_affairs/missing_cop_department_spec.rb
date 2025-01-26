# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/internal_affairs/missing_cop_department'

RSpec.describe RuboCop::Cop::InternalAffairs::MissingCopDepartment do
  it 'flags use of `Cop/` department' do
    expect_offense(<<~RUBY)
      module ::RuboCop
        module Cop
          class Name
                ^^^^ Define a proper department. Using `Cop/` as department is discourged.
            def on_send(node)
            end
          end
        end
      end

      class RuboCop::Cop::Name
            ^^^^^^^^^^^^^^^^^^ Define a proper department. Using `Cop/` as department is discourged.
        def on_send(node)
        end
      end

      module RuboCop
        class Cop::Name
              ^^^^^^^^^ Define a proper department. Using `Cop/` as department is discourged.
          def on_send(node)
          end
        end
      end
    RUBY
  end

  it 'flags explicit use of `Cop/` department' do
    expect_offense(<<~RUBY)
      module RuboCop
        module Cop
          module Cop
            class Name
                  ^^^^ Define a proper department. Using `Cop/` as department is discourged.
              def on_send(node)
              end
            end
          end
        end
      end

      class RuboCop::Cop::Cop::Name
            ^^^^^^^^^^^^^^^^^^^^^^^ Define a proper department. Using `Cop/` as department is discourged.
        def on_send(node)
        end
      end

      module RuboCop::Cop
        class Cop::Name
              ^^^^^^^^^ Define a proper department. Using `Cop/` as department is discourged.
          def on_send(node)
          end
        end
      end
    RUBY
  end

  it 'flags arbitary namespaces' do
    expect_offense(<<~RUBY)
      module Foo
        module Bar
          class Name
                ^^^^ Define a proper department. Using `Cop/` as department is discourged.
            def on_send(node)
            end
          end
        end
      end
    RUBY
  end

  it 'does not flag cops with departments' do
    expect_no_offenses(<<~RUBY)
      module RuboCop
        module Cop
          module Department
            class Name
              def on_send(node)
              end
            end
          end
        end
      end

      class RuboCop::Cop::Department::Name
        def on_send(node)
        end
      end

      module RuboCop
        class Cop::Department::Name
          def on_send(node)
          end
        end
      end
    RUBY
  end
end
