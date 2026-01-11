# frozen_string_literal: true

module KDK
  module Services
    class DuoWorkflowService < Base
      def name
        'duo-workflow-service'
      end

      def command
        'support/exec-cd khulnasoft-ai-gateway poetry run duo-workflow-service'
      end

      def env
        { 'PORT' => config.duo_workflow.port }
      end

      def enabled?
        config.duo_workflow?
      end

      def ready_message
        "Duo Workflow Service is available at #{config.hostname}:#{config.duo_workflow.port}"
      end
    end
  end
end
