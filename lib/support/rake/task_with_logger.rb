# frozen_string_literal: true

module Support
  module Rake
    module TaskWithLogger
      MakeError = Class.new(StandardError) do
        def initialize(target)
          super("`make #{target}` failed.")
        end
      end

      LoggerError = Class.new(StandardError) do
        def initialize(task, error, logger)
          @task = task
          @error = error
          @logger = logger
          @logger.mark_as_failed!(task)
          super("Task `#{@task.name}` failed")
        end

        def print!
          tail = @logger.tail.strip.split("\n").map { |l| "  #{l}" }.join("\n")
          KDK::Output.error("Task \e[32m#{@task.name}\e[0m failed:\n\n#{tail}", report_error: false)
          KDK::Output.puts
        end
      end

      def execute(...)
        # The TaskLogger has no proxy mode, so it would swallow all logs
        # for tasks that don't run in the context of a spinner.
        return super unless TaskWithSpinner.spinner_manager

        begin
          logger = TaskLogger.from_task(self)
          TaskLogger.set_current!(logger)
          super
          logger.cleanup!
        rescue StandardError => e
          if logger
            unless e.is_a?(MakeError)
              warn e.message
              warn e.backtrace
            end

            raise if e.is_a?(KDK::UserInteractionRequired)

            error = LoggerError.new(self, e, logger)

            tail = logger.tail(max_lines: 100, exclude_gems: false)

            if tail.include?('Failed to open TCP connection to sentry.example.com')
              raise KDK::UserInteractionRequired,
                <<~MSG
                  You've configured your local KhulnaSoft instance to use a non-existent Sentry host. This is unsupported because it fails specific Rake tasks invoked by KDK.

                  Please disable the Sentry settings in your KhulnaSoft installation in Admin > Settings > Metrics and profiling > Sentry.
                MSG
            end

            attachment = { filename: "log/#{name}.txt", bytes: KDK::ConfigRedactor.new.redact_logfile(tail) }
            KDK::Telemetry.capture_exception(error, attachment: attachment)

            raise error
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
