# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Enforces the use of explicit department names for cop rules.
      #
      # @example
      #   # bad
      #   module RuboCop
      #     module Cop
      #       class Implicit
      #       end
      #     end
      #   end
      #
      #   module RuboCop
      #     module Cop
      #       module Cop
      #         class Explicit
      #         end
      #       end
      #     end
      #   end
      #
      #   # good
      #   module RuboCop
      #     module Cop
      #       module Foo
      #         class Implicit
      #         end
      #       end
      #     end
      #   end
      #
      #   module RuboCop
      #     module Cop
      #       module Foo
      #         class Explicit
      #         end
      #       end
      #     end
      #   end
      class MissingCopDepartment < Base
        MSG = 'Define a proper department. Using `Cop/` as department is discourged.'

        COP_DEPARTMENT = 'Cop'

        def on_class(node)
          namespace = full_namespace(node)

          # Skip top-level RuboCop::Cop
          names = namespace.drop(2)

          add_offense(node.loc.name) if names.size < 2 || names.first == COP_DEPARTMENT
        end

        private

        def full_namespace(node)
          (node_namespace(node) + parents_namespace(node)).reverse
        end

        def node_namespace(node)
          name_parts(node).reverse
        end

        def parents_namespace(node)
          node
            .each_ancestor(:module, :class)
            .flat_map { |node| name_parts(node) }
        end

        def name_parts(node)
          node.identifier.source.split('::')
        end
      end
    end
  end
end
