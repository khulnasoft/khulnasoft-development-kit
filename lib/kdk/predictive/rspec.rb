# frozen_string_literal: true

require 'net/http'
require 'json'

module KDK
  module Predictive
    class Rspec < Base
      TEST_MAPPING_FILE = 'tests.yml'
      KNAPSACK_REPORT_URL = 'https://khulnasoft-org.khulnasoft.io/khulnasoft/knapsack/report-master.json'
      CONFIRMATION_THRESHOLD = 30 # seconds

      def execute(force: false)
        if changed_files.empty?
          out.info 'No changes detected. No tests will be run.'
          return true
        end

        if test_mapping.empty?
          out.warn "No tests related to the following changes were found:\n#{changed_files}"
          return true
        end

        out.puts "Testing against\n#{test_mapping}\nbased on the changes detected in the following files:\n#{changed_files}"
        out.warn 'If you are running tests for the first time, the setup might take a while.'

        knapsack_report_output

        return true if estimated_runtime > CONFIRMATION_THRESHOLD && !(force || confirm?)

        out.puts 'Running predicted tests ...'
        run_predicted_tests
      end

      private

      def changed_files
        @changed_files ||= all_changed_files.join("\n")
      end

      def retrieve_static_test_mapping
        shellout("bundle exec tff -f #{TEST_MAPPING_FILE} #{changed_files.split("\n").join(' ')}", chdir: khulnasoft_dir)
      end

      def retrieve_crystalball_described_class_mapping
        cmd = %w[./tooling/bin/predictive_tests --with-crystalball-mappings --with-frontend-fixture-mappings --mapping-type described_class]

        shellout(cmd, chdir: khulnasoft_dir)
      end

      def test_mapping
        @test_mapping ||= (retrieve_static_test_mapping.split("\n") | retrieve_crystalball_described_class_mapping.split).join("\n")
      end

      def confirm?
        out.prompt('Are you sure you want to continue? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def knapsack_report_output
        if knapsack_report.empty?
          out.puts('No knapsack report available. Running the tests might take a long time.')
        else
          out.puts("The estimated runtime of the tests is: #{Utils.format_duration(estimated_runtime)}.")
        end
      end

      def run_predicted_tests
        spec_files_by_spec_helper.each_value.map do |specs|
          sh = Shellout.new("bundle exec rspec #{specs.join(' ')}", chdir: khulnasoft_dir)
          sh.stream
          sh.success?
        end.all?
      end

      def spec_files_by_spec_helper
        test_mapping.split("\n").group_by do |path|
          use_fast_spec_helper?(path) ? :fast_spec_helper : :spec_helper
        end
      end

      def use_fast_spec_helper?(specfile_path)
        File.foreach(khulnasoft_dir.join(specfile_path)).grep(/require 'fast_spec_helper'/).any?
      rescue Errno::ENOENT
        false
      end

      def estimated_runtime
        @estimated_runtime ||= test_mapping.split("\n").sum do |spec_path|
          # Missing specs default to 0.0 runtime for estimation
          knapsack_report[spec_path].to_f
        end
      end

      def knapsack_report
        @knapsack_report ||= begin
          JSON.parse(Net::HTTP.get(URI(KNAPSACK_REPORT_URL)))
        rescue StandardError => e
          out.warn "Failed to fetch knapsack report: #{e.message}"
          {}
        end
      end
    end
  end
end
