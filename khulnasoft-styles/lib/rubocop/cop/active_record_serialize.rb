# frozen_string_literal: true

module Rubocop
  module Cop
    # Cop that prevents the use of `serialize` in ActiveRecord models.
    #
    # @example
    #   # bad
    #   serialize :preferences
    #
    #   # good
    #   # Column for each individual preference
    class ActiveRecordSerialize < RuboCop::Cop::Base
      MSG = 'Do not store serialized data in the database, use separate columns and/or tables instead'

      RESTRICT_ON_SEND = %i[serialize].freeze

      def on_send(node)
        return if node.receiver

        add_offense(node.loc.selector)
      end
    end
  end
end
