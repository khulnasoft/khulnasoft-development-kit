# frozen_string_literal: true

module KDK
  module Predictive
    class Base
      def out
        KDK::Output
      end

      def all_changed_files
        @all_changed_files ||= "#{shellout('git diff --name-only -z', chdir: khulnasoft_dir)}\0" \
          "#{shellout('git diff origin/master...HEAD --name-only -z', chdir: khulnasoft_dir)}"
          .split("\0")
          .reject(&:empty?)
          .uniq
      end

      def khulnasoft_dir
        @khulnasoft_dir ||= KDK.config.khulnasoft.dir
      end

      def shellout(cmd, **args)
        Shellout.new(cmd, **args).run
      rescue StandardError => e
        raise "Failed to execute shell command: #{e.message}"
      end
    end
  end
end
