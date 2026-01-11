# frozen_string_literal: true

module KDK
  module ConfigType
    module Mergable
      def read_value
        val = super

        return val if !merge || !user_defined?

        mergable_merge(user_value, default_value)
      end

      private

      def merge
        kwargs[:merge]
      end
    end
  end
end
