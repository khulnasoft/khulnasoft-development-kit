# frozen_string_literal: true

require_relative '../../../khulnasoft/styles/rubocop/migration_helpers'

module Rubocop
  module Cop
    module Migration
      # Checks for methods that may lead to batch type issues on a table that's been
      # explicitly denied because of its size.
      #
      # Even though though these methods perform functions to avoid
      # downtime, using it with tables with millions of rows still causes a
      # significant delay in the deploy process and is best avoided.
      #
      # See https://khulnasoft.com/khulnasoft-com/infrastructure/issues/1602 for more
      # information.
      class UpdateLargeTable < RuboCop::Cop::Base
        include Khulnasoft::Styles::Rubocop::MigrationHelpers

        MSG = 'Using `%s` on the `%s` table will take a long time to ' \
          'complete, and should be avoided unless absolutely ' \
          'necessary'

        # @!method batch_update?(node)
        def_node_matcher :batch_update?, <<~PATTERN
          (send nil? ${#denied_method?}
            (sym $...)
            ...)
        PATTERN

        def on_send(node)
          return if denied_tables.empty? || denied_methods.empty?
          return unless in_migration?(node)

          matches = batch_update?(node)
          return unless matches

          update_method = matches.first
          table = matches.last.to_a.first

          return unless denied_tables.include?(table)

          add_offense(node, message: format(MSG, update_method, table))
        end

        private

        def denied_tables
          cop_config['DeniedTables'] || []
        end

        def denied_method?(method_name)
          denied_methods.include?(method_name)
        end

        def denied_methods
          cop_config['DeniedMethods'] || []
        end
      end
    end
  end
end
