# frozen_string_literal: true

module Rubocop
  module Cop
    # Cop that prevents the use of `dependent: ...` in ActiveRecord models.
    # @example
    #   # bad
    #   belongs_to :foo, dependent: :destroy
    #
    #   # good
    #   belongs_to :foo # With database foreign key with cascading deletes
    class ActiveRecordDependent < RuboCop::Cop::Base
      MSG = 'Do not use `dependent:` to remove associated data, ' \
        'use foreign keys with cascading deletes instead.'

      RESTRICT_ON_SEND = %i[has_many has_one belongs_to].to_set.freeze
      ALLOWED_OPTIONS = %i[restrict_with_error].freeze

      # @!method dependent_use(node)
      def_node_matcher :dependent_use, <<~PATTERN
        (send _ %RESTRICT_ON_SEND ... (hash <$(pair (sym :dependent) (sym $_)) ...>))
      PATTERN

      def on_send(node)
        dependent_use(node) do |pair, value|
          add_offense(pair) unless ALLOWED_OPTIONS.include?(value)
        end
      end
    end
  end
end
