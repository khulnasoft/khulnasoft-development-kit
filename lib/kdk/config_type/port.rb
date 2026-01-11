# frozen_string_literal: true

module KDK
  module ConfigType
    class Port < Integer
      def parse(value)
        return super if parent.respond_to?(:enabled?) && !parent.enabled?

        super.tap do |validated_value|
          config.port_manager.claim(validated_value, service_name)
        end
      end

      def default_value
        super || config.port_manager.default_port_for_service(service_name)
      end

      private

      def service_name
        kwargs[:service_name]
      end
    end
  end
end
