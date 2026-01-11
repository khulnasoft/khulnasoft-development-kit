# frozen_string_literal: true

module KDK
  module Complib
    class ComponentDsl
      def initialize(name)
        @name = name
      end

      def feature_category(feature_category)
        component.feature_category = feature_category
      end

      def smoke_test(title, &blk)
        component.smoke_tests[title] = blk
      end

      def template(**args)
        args[:template] = "components/#{@name}/#{args[:template]}" if args.key?(:template)

        component.templates << KDK::TaskHelpers::Task.new(**args)
      end

      def component
        @component ||= Component.new(name: @name)
      end
    end
  end
end
