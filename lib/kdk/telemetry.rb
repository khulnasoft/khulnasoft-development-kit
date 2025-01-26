# frozen_string_literal: true

autoload :KhulnasoftSDK, 'khulnasoft-sdk'
autoload :Sentry, 'sentry-ruby'
autoload :SnowplowTracker, 'snowplow-tracker'

module KDK
  module Telemetry
    ANALYTICS_APP_ID = 'e2e967c0-785f-40ae-9b45-5a05f729a27f'
    ANALYTICS_BASE_URL = 'https://collector.prod-1.gl-product-analytics.com'
    SENTRY_DSN = 'https://4e771163209528e15a6a66a6e674ddc3@new-sentry.khulnasoft.net/38'
    PROMPT_TEXT = <<-TEXT
      To improve KDK, KhulnaSoft would like to collect basic error and usage, including your platform and architecture. Please choose one of the following options:

      - To send data to KhulnaSoft, enter your KhulnaSoft username.
      - To send data to KhulnaSoft anonymously, leave blank.
      - To avoid sending data to KhulnaSoft, enter a period ('.').
    TEXT

    def self.with_telemetry(command)
      return yield unless telemetry_enabled?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      result = yield

      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      send_telemetry(result, command, {
        duration: duration,
        environment: environment,
        platform: KDK::Machine.platform,
        architecture: KDK::Machine.architecture,
        version_manager: version_manager,
        team_member: team_member?
      })

      result
    end

    def self.send_telemetry(success, command, payload = {})
      # This is tightly coupled to KDK commands and returns false when the system call exits with a non-zero status.
      status = success ? 'Finish' : 'Failed'

      client.identify(KDK.config.telemetry.username)
      client.track("#{status} #{command} #{ARGV}", payload)
    end

    def self.flush_events(async: false)
      client.flush_events(async: async)
    end

    def self.environment
      KDK.config.telemetry.environment
    end

    def self.version_manager
      return 'asdf' unless KDK.config.asdf.opt_out?
      return 'mise' if KDK.config.mise.enabled?

      'none'
    end

    def self.client
      return @client if @client

      app_id = ENV.fetch('KHULNASOFT_SDK_APP_ID', ANALYTICS_APP_ID)
      host = ENV.fetch('KHULNASOFT_SDK_HOST', ANALYTICS_BASE_URL)

      SnowplowTracker::LOGGER.level = Logger::WARN
      @client = KhulnasoftSDK::Client.new(app_id: app_id, host: host)
    end

    def self.init_sentry
      Sentry.init do |config|
        config.dsn = SENTRY_DSN
        config.breadcrumbs_logger = [:sentry_logger]
        config.traces_sample_rate = 1.0
        config.logger.level = Logger::WARN

        config.before_send = lambda do |event, hint|
          exception = hint[:exception]

          # Workaround for using fingerprint to make certain errors distinct.
          # See https://khulnasoft.com/khulnasoft-org/opstrace/opstrace/-/issues/2842#note_1927103517
          event.transaction = exception.message if exception.is_a?(Shellout::ShelloutBaseError)

          event
        end
      end

      Sentry.set_user(username: KDK.config.telemetry.username)
    end

    def self.capture_exception(message)
      return unless telemetry_enabled?

      if message.is_a?(Exception)
        exception = message.dup
      else
        exception = StandardError.new(message)
        exception.set_backtrace(caller)
      end

      # Drop the caller KDK::Telemetry.capture_exception to make errors distinct.
      exception.set_backtrace(exception.backtrace.drop(1)) if exception.backtrace

      init_sentry
      Sentry.capture_exception(exception, extra: {
        environment: environment,
        platform: KDK::Machine.platform,
        architecture: KDK::Machine.architecture,
        version_manager: version_manager,
        team_member: team_member?
      })
    end

    def self.telemetry_enabled?
      KDK.config.telemetry.enabled
    end

    # Returns true if the user has configured a @khulnasoft.com email for git.
    #
    # This should only be used for telemetry and NEVER for authentication.
    def self.team_member?
      Shellout.new(%w[git config --get user.email], chdir: KDK.config.kdk_root)
        .run.include?('@khulnasoft.com')
    end

    def self.update_settings(username)
      enabled = true
      username = username.to_s

      if username.empty?
        username = SecureRandom.hex
      elsif username == '.'
        username = ''
        enabled = false
      end

      KDK.config.bury!('telemetry.enabled', enabled)
      KDK.config.bury!('telemetry.username', username)
      KDK.config.save_yaml!
    end
  end
end
