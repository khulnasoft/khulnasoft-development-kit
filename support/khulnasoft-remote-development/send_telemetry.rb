#!/usr/bin/env ruby
#
# frozen_string_literal: true

require 'timeout'
require_relative '../../lib/kdk'

class SendTelemetry
  KDK_ROOT_DIR = ENV.fetch('KDK_ROOT_DIR', '/projects/khulnasoft-development-kit').freeze
  KDK_SETUP_FLAG_FILE = File.join(KDK_ROOT_DIR, '.cache', '.kdk_setup_complete').freeze
  KDK_TELEMETRY_FLAG_FILE = File.join(KDK_ROOT_DIR, '.cache', '.kdk_setup_telemetry_sent').freeze
  SETUP_TIMEOUT_SECONDS = ENV.fetch('SETUP_TIMEOUT_SECONDS', 30 * 60).to_i.freeze
  POSTSTART_LOG_FILE = '/projects/workspace-logs/poststart-stdout.log'

  def run
    unless workspace_environment?
      KDK::Output.info("Nothing to do as we're not a KhulnaSoft Workspace")
      return
    end

    KDK::Output.error("Waited #{SETUP_TIMEOUT_SECONDS} seconds for setup to finish. Check the workspace logs for any errors.") unless wait_for_setup_flag_file(SETUP_TIMEOUT_SECONDS)

    success, duration = last_run_status

    return if telemetry_sent?

    send_telemetry(success, duration) if allow_sending_telemetry?
    FileUtils.touch(KDK_TELEMETRY_FLAG_FILE)

    if success
      KDK::Output.success("You can access your KDK here: https://#{url}")
    else
      KDK::Output.error('Workspace setup failed. Check the workspace logs for any errors.')
    end
  end

  private

  def workspace_environment?
    !ENV['KS_WORKSPACE_DOMAIN_TEMPLATE'].to_s.empty?
  end

  def wait_for_setup_flag_file(timeout_seconds)
    start_time = Time.now
    KDK::Output.info <<~TEXT
    Waiting up to #{timeout_seconds} seconds for KDK setup to complete...
    To follow the progress:
      1. Open a new terminal
      2. tail -f /projects/workspace-logs/poststart-stdout.log
    TEXT

    sleep 5 until File.exist?(KDK_SETUP_FLAG_FILE) || (Time.now - start_time) > timeout_seconds

    File.exist?(KDK_SETUP_FLAG_FILE)
  end

  def send_telemetry(success, duration)
    extra_args = ["--extra=success:#{success}"]

    if File.exist?(POSTSTART_LOG_FILE)
      content = File.read(POSTSTART_LOG_FILE)

      match = content.match(/Execution times for each function:\s*\n(.*)/m)
      if match
        data = match[1]
        data.each_line do |line|
          # Match lines like "update_kdk: 479 seconds"
          line.scan(/^(\w+):\s+(\d+)\s+seconds$/) do |function_name, duration|
            extra_args << "--extra=#{function_name}:#{duration}"
          end
        end
      end
    end

    Timeout.timeout(5) do
      success = system('kdk', 'send-telemetry', 'workspace_setup_duration', duration.to_s, *extra_args)
      KDK::Output.warn("Failed to send workspace setup duration via telemetry command.") unless success
    end
  rescue Timeout::Error
    KDK::Output.warn("Telemetry command timed out.")
  end

  def allow_sending_telemetry?
    KDK.config.telemetry.enabled
  end

  def last_run_status
    return false, nil unless File.exist?(KDK_SETUP_FLAG_FILE)
    return false, nil if File.empty?(KDK_SETUP_FLAG_FILE)

    exit_code, seconds = File.read(KDK_SETUP_FLAG_FILE).split
    [exit_code.to_i.zero?, seconds.to_i]
  end

  def telemetry_sent?
    return false unless File.exist?(KDK_TELEMETRY_FLAG_FILE)

    File.mtime(KDK_SETUP_FLAG_FILE) < File.mtime(KDK_TELEMETRY_FLAG_FILE)
  end

  def url
    port = ENV.find { |key, _| key.include?('SERVICE_PORT_KDK') }&.last
    ENV.fetch('KS_WORKSPACE_DOMAIN_TEMPLATE', '').gsub('${PORT}', port.to_s)
  end
end

SendTelemetry.new.run if $PROGRAM_NAME == __FILE__
