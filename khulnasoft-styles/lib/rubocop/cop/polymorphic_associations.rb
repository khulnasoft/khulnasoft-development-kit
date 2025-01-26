# frozen_string_literal: true

module Rubocop
  module Cop
    # Cop that prevents the use of polymorphic associations
    class PolymorphicAssociations < RuboCop::Cop::Base
      MSG = 'Do not use polymorphic associations, use separate tables instead'

      RESTRICT_ON_SEND = %i[belongs_to].to_set.freeze

      # @!method polymorphic_pair(node)
      def_node_matcher :polymorphic_pair, <<~PATTERN
        (send _ %RESTRICT_ON_SEND ... (hash <$(pair (sym :polymorphic) _) ...>))
      PATTERN

      def on_send(node)
        polymorphic_pair(node) do |pair|
          add_offense(pair)
        end
      end
    end
  end
end
