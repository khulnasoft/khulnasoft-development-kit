# frozen_string_literal: true

module KDK
  module Complib
    class PipelineSchemaGenerator
      BASE = <<~YAML
        .base-component:test:
          tags: [saas-linux-large-amd64]
          stage: test
          image:  ${VERIFY_IMAGE}
          variables:
            GIT_STRATEGY: none

        workflow:
          rules:
            - if: '$CI_PIPELINE_SOURCE == "parent_pipeline"'
      YAML

      def initialize(component)
        @component = component
      end

      def to_yaml
        <<~YAML
          component:#{component.name}:test:
            extends: .base-component:test
            script:
              - unset BUNDLE_PATH
              - echo "Testing component #{component.name}"
              - pwd
              - ls -alh
              - cd $HOME/kdk
              - git status
              - kdk component verify '#{component.name}'
        YAML
      end

      private

      attr_reader :component
    end
  end
end
