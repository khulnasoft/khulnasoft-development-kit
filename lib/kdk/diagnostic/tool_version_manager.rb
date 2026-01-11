# frozen_string_literal: true

require 'json'

module KDK
  module Diagnostic
    # Notifies users about the supported tool version manager.
    class ToolVersionManager < Base
      TITLE = 'Tool Version Manager'

      def correctable?
        mise_update_command && mise_update_required?
      end

      def correct!
        update_mise! if correctable?
      end

      def success?
        !mise_update_required?
      end

      def detail
        return if success?

        messages = []

        messages << <<~MESSAGE
          WARNING: Your installed version of mise (#{current_mise_version}) is out of date.
          The latest available version is #{mise_latest_version}.
        MESSAGE

        if mise_update_command
          messages << <<~MESSAGE
            To update to the latest version, run:
              `#{mise_update_command}`
          MESSAGE
        end

        messages.join("\n")
      end

      private

      def using_mise?
        KDK.config.tool_version_manager.enabled?
      end

      def mise_version_output
        @mise_version_output ||= begin
          output = KDK::Shellout.new('mise version --json').execute(display_output: false).read_stdout
          JSON.parse(output)
        rescue Errno::ENOENT, JSON::ParserError
          {}
        end
      end

      def current_mise_version
        mise_version_output['version']&.split&.first
      end

      def mise_latest_version
        mise_version_output['latest']
      end

      def mise_update_command
        if KDK::Machine.macos?
          'brew update && brew upgrade mise'
        elsif KDK::Machine.linux?
          'apt update && apt upgrade mise'
        end
      end

      def mise_update_required?
        return false unless using_mise?

        return false unless current_mise_version && mise_latest_version

        begin
          current_version = Gem::Version.new(current_mise_version)
          latest_version = Gem::Version.new(mise_latest_version)

          current_version < latest_version
        rescue ArgumentError
          false
        end
      end

      def update_mise!
        KDK::Shellout.new(mise_update_command).execute(display_output: false)
        true
      rescue StandardError => e
        KDK::Output.warn("Failed to update mise: #{e.message}")
        false
      end
    end
  end
end
