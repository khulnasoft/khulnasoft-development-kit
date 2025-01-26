# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class TaskLogger
      def self.set_current!(logger)
        Thread.current[:kdk_task_logger] = logger
      end

      def self.current
        Thread.current[:kdk_task_logger]
      end

      def self.start_time
        @start_time ||= Time.now
      end

      attr_reader :file_path

      def initialize(task)
        @file_path = "#{logs_dir}/#{task.name.gsub(%r{[:\s/.]+}, '-')}.log"

        create_logs_dir!
      end

      def file
        @file ||= File.open(@file_path, 'w').tap { |file| file.sync = true }
      end

      def cleanup!(delete: true)
        return if @file&.closed?

        File.delete(@file_path) if @file&.size === 0 && delete
        @file&.close
      end

      private

      def create_logs_dir!
        FileUtils.mkdir_p(logs_dir)
      end

      def logs_dir
        "#{KDK.root}/log/kdk/rake-#{TaskLogger.start_time.strftime('%Y-%m-%d_%H-%M-%S_%L')}"
      end
    end
  end
end

# Inspired by https://stackoverflow.com/a/16184325/6403374
# but adjusted so we can use it with our own task logger
#
# We use __send__ to proxy IO function on Kernel.
# rubocop:disable KhulnasoftSecurity/PublicSend
module Kernel
  [:printf, :p, :print, :puts, :warn].each do |method|
    name = "__#{method}__"

    alias_method name, method

    define_method(method) do |*args|
      logger = Support::Rake::TaskLogger.current
      return __send__(name, *args) unless logger

      kdk_rake_log_lock.synchronize do
        $stdout = logger.file
        $stderr = logger.file
        __send__(name, *args)
      ensure
        $stdout = STDOUT
        $stderr = STDERR
      end
    end
  end

  private

  def kdk_rake_log_lock
    @kdk_rake_log_lock ||= Mutex.new
  end
end
# rubocop:enable KhulnasoftSecurity/PublicSend
