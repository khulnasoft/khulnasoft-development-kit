# frozen_string_literal: true

module Khulnasoft
  module Styles
    module Rubocop
      # Module containing helper methods for writing migration cops.
      module MigrationHelpers
        # Returns true if the given node originated from the db/migrate directory.
        def in_migration?(node)
          dirname = File.dirname(node.source_range.source_buffer.name)

          dirname.end_with?(
            'db/migrate',
            'db/post_migrate',
            'ee/db/migrate',
            'ee/db/post_migrate')
        end
      end
    end
  end
end
