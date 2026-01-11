# frozen_string_literal: true

module KDK
  module Predictive
    class Jest < Base
      def execute(_ = [])
        if changed_js_files.empty?
          out.info 'No changes were detected in JavaScript files. Nothing to do.'
          true
        else
          out.info "Detected changes in JavaScript files:\n#{changed_js_files}"
          download_and_extract_fixtures
          run_jest_related_tests
        end
      end

      private

      def changed_js_files
        @changed_js_files ||= all_changed_files
          .select { |file| file.end_with?('.js', '.cjs', '.mjs', '.vue', '.graphql') }
      end

      def download_and_extract_fixtures
        Shellout.new(
          'scripts/frontend/download_fixtures.sh --branch master',
          chdir: khulnasoft_dir
        ).stream
      end

      def run_jest_related_tests
        cmd = Utils.prefix_command(
          'bundle', 'exec', 'yarn', 'jest', '--passWithNoTests', '--findRelatedTests', *changed_js_files
        )

        sh = Shellout.new(*cmd, chdir: khulnasoft_dir)
        sh.stream
        sh.success?
      end
    end
  end
end
