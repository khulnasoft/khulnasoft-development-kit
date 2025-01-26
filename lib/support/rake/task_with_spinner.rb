# frozen_string_literal: true

begin
  require 'tty-spinner'
rescue LoadError
end

module Support
  module Rake
    module TaskWithSpinner
      class << self
        attr_accessor :spinner_manager
      end

      TaskSkippedError = Class.new(StandardError)

      def enable_spinner!
        return unless KDK::Output.interactive?
        return unless defined?(TTY::Spinner)

        @enable_spinner = true
      end

      def invoke(...)
        if @enable_spinner
          TaskWithSpinner.spinner_manager&.stop
          TaskWithSpinner.spinner_manager = ::TTY::Spinner::Multi.new(
            spinner_name,
            success_mark: "\e[32m#{TTY::Spinner::TICK}\e[0m",
            error_mark: "\e[31m#{TTY::Spinner::CROSS}\e[0m",
            format: :dots,
            # $stderr is overwritten in TaskWithLogger
            output: STDERR # rubocop:disable Style/GlobalStdStream
          )
        end

        super
      ensure
        TaskWithSpinner.spinner_manager&.stop if @enable_spinner
      end

      def execute(...)
        @kdk_execute_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        spinner = nil
        if TaskWithSpinner.spinner_manager && show_spinner?
          thread = Thread.new do
            sleep 0.001
            next if @skipped

            spinner = TaskWithSpinner.spinner_manager.register spinner_name
            spinner.auto_spin
          end
        end

        super
      rescue StandardError => e
        spinner&.error(execution_duration_message)
        raise e unless e.instance_of?(TaskSkippedError)
      else
        spinner&.success(execution_duration_message)
      ensure
        thread&.join
      end

      def skip!
        @skipped = true
        raise TaskSkippedError
      end

      private

      # A task without action (i.e. do ... end block) will finish
      # instantly after all dependencies have finished, so we don't want
      # to show a spinner for it.
      def show_spinner?
        !actions.empty?
      end

      def spinner_name
        ":spinner #{comment || name}"
      end

      def execution_duration_message
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@kdk_execute_start || 0)
        "[#{format_duration(duration)}]"
      end

      def format_duration(seconds)
        return "#{(seconds * 1000).floor}ms" if seconds < 1
        return "#{seconds.round}s" if seconds < 60

        "#{(seconds / 60).floor}m #{seconds.round % 60}s"
      end
    end
  end
end
