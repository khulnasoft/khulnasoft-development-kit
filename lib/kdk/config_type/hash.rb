# frozen_string_literal: true

require 'json'

module KDK
  module ConfigType
    class Hash < Base
      include Mergable
      include CoreHelper::DeepHash

      def parse(value)
        return parse_json_string(value) if value.is_a?(::String)

        stringify_values? ? value.to_h.transform_values(&:to_s) : value.to_h
      end

      def dump!(user_only: false)
        user_only ? @user_value : super
      end

      private

      def mergable_merge(fetched, default)
        deep_merge(default, Hash(fetched))
      end

      def stringify_values?
        builder.kwargs[:stringify_values]
      end

      def parse_json_string(value)
        JSON.parse(value)
      rescue JSON::ParserError => e
        raise StandardErrorWithMessage, e.message
      end
    end
  end
end
