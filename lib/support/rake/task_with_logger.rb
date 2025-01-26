# frozen_string_literal: true

module Support
  module Rake
    module TaskWithLogger
      def execute(...)
        # kdk-config.mk is included in the Makefile, so it must output
        # nothing, ever.
        return super if name == "kdk-config.mk"
        return super unless TaskWithSpinner.spinner_manager

        begin
          logger = TaskLogger.new(self)
          TaskLogger.set_current!(logger)
          super
          logger.cleanup!
        rescue StandardError => e
          if logger
            warn e.message
            warn e.backtrace
            raise e, "#{name} failed!\nSee #{logger.file_path} for the task output.\n"
          end

          raise
        ensure
          logger&.cleanup!(delete: false)
          TaskLogger.set_current!(nil)
        end
      end
    end
  end
end
