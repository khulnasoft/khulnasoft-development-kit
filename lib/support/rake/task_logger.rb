# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class TaskLogger
      SCORING_PATTERNS = [
        { pattern: /ERROR:|FATAL:|failed|aborted!|PG::|ActiveRecord::/i, score: 15 },
        { pattern: /WARNING:|WARN:|from.*\.rb:\d+/i, score: 8 },
        { pattern: %r{\[sentry\]|mise all tools|/ruby/gems/}i, score: -3 }
      ].freeze

      def self.set_current!(logger)
        Thread.current[:kdk_task_logger] = logger
      end

      def self.current
        Thread.current[:kdk_task_logger]
      end

      def self.start_time
        @start_time ||= Time.now
      end

      def self.from_task(task)
        new("#{TaskLogger.logs_dir}/#{task.name.gsub(%r{[:\s/.]+}, '-')}.log")
      end

      def self.logs_dir
        "#{KDK.root}/log/kdk/rake-#{TaskLogger.start_time.strftime('%Y-%m-%d_%H-%M-%S_%L')}"
      end

      def self.create_latest_symlink!
        link_name = "#{KDK.root}/log/kdk/rake-latest"
        logs_dir = TaskLogger.logs_dir

        return unless Dir.exist?(logs_dir)

        FileUtils.rm_rf(link_name) if File.exist?(link_name) || File.symlink?(link_name)
        FileUtils.ln_sf(TaskLogger.logs_dir, link_name)
      end

      attr_reader :file_path, :recent_line

      def initialize(file_path)
        @file_path = Pathname(file_path)

        create_logs_dir!
      end

      def file
        @file ||= File.open(@file_path, 'w').tap { |file| file.sync = true }
      end

      # Input must have at least one valid char. This excludes newlines and separators-only lines.
      INPUT_REGEXP = /\w/
      # Rails noise.
      IGNORE_INPUT_NOISE = 'DEPRECATION WARNING'

      private_constant :INPUT_REGEXP, :IGNORE_INPUT_NOISE

      def mark_as_failed!(task)
        @file.puts("[#{Time.now.strftime('%F %T.%6N')}] ERROR: --- Task #{task.name} failed ---")
      end

      def record_input(string)
        return unless string

        recent_line = string
          .split("\n")
          .reverse_each
          .find { |line| !line.include?(IGNORE_INPUT_NOISE) && INPUT_REGEXP.match?(line) }

        @recent_line = recent_line if recent_line
      end

      def cleanup!(delete: true)
        return if @file&.closed?

        File.delete(@file_path) if @file&.size === 0 && delete
        @file&.close
      end

      def tail(max_lines: 25, exclude_gems: true, only_with_errors: false, smart_filter: false)
        lines = File.read(@file_path).scrub('?').split("\n")
        return if only_with_errors && !has_errors?(lines)

        original_line_count = lines.length
        lines = lines.reject { |l| l.include?('/ruby/gems/') } if exclude_gems

        lines = if smart_filter
                  smart_filter_lines(lines, max_lines)
                else
                  lines.last(max_lines)
                end

        truncated = original_line_count - lines.length
        lines.push('', "... #{truncated} lines omitted. See #{@file_path} for the full log.") if truncated.positive?

        lines.join("\n")
      end

      private

      def smart_filter_lines(lines, max_lines)
        return lines if lines.length <= max_lines

        scores = calculate_line_scores(lines)
        top_indices = select_top_indices(scores, max_lines)
        top_indices.map { |idx| lines[idx] }
      end

      def calculate_line_scores(lines)
        base_scores = lines.map do |line|
          SCORING_PATTERNS.sum { |p| line.match?(p[:pattern]) ? p[:score] : 0 }
        end

        base_scores.each_with_index.map do |score, idx|
          score + calculate_proximity_bonus(base_scores, idx)
        end
      end

      def select_top_indices(scores, count)
        (0...scores.length).to_a
          .sort_by! { |idx| [-scores[idx], idx] }
          .first(count)
          .sort!
      end

      def calculate_proximity_bonus(base_scores, idx)
        bonus = 0.0
        max_idx = base_scores.length - 1

        (-3..3).each do |offset|
          next if offset.zero?

          neighbor_idx = idx + offset
          next if neighbor_idx.negative? || neighbor_idx > max_idx

          neighbor_score = base_scores[neighbor_idx]
          bonus += neighbor_score * 0.2 / offset.abs if neighbor_score.positive?
        end

        bonus.round
      end

      def has_errors?(lines)
        lines.any? { |line| line.match?(/\b(error|err|fatal?)\b/i) }
      end

      def create_logs_dir!
        file_path.parent.mkpath
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

at_exit do
  Support::Rake::TaskLogger.create_latest_symlink!
end
