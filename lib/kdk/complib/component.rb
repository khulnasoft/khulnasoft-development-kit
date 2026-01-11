# frozen_string_literal: true

module KDK
  module Complib
    FIELDS = %i[name feature_category smoke_tests templates].freeze
    REQUIRED_FIELDS = %i[name feature_category].freeze

    Component = Struct.new(*FIELDS) do
      def initialize(...)
        super

        self.smoke_tests ||= {}
        self.templates ||= []
      end

      def smoke_test!
        self.smoke_tests.each do |key, method|
          KDK::Output.info("Testing '#{key}'...")
          Class.new.extend(SmokeTestHelper).instance_exec(&method)
        end

        missing = missing_fields
        return if missing.empty?

        raise "Component #{name} is missing required fields: #{missing.join(', ')}"
      end

      private

      def missing_fields
        REQUIRED_FIELDS.reject { |field| send(field) } # rubocop:disable KhulnasoftSecurity/PublicSend -- we know the field exists
      end
    end
  end
end
