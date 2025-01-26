# frozen_string_literal: true

module Rubocop
  module Cop
    # Cop that prevents the use of `in_batches`
    class InBatches < RuboCop::Cop::Base
      MSG = 'Do not use `in_batches`, use `each_batch` from the EachBatch module instead'

      RESTRICT_ON_SEND = %i[in_batches].freeze

      def on_send(node)
        add_offense(node.loc.selector)
      end
    end
  end
end
