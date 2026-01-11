# frozen_string_literal: true

module KDK
  # Utility functions related to KDK dependencies
  module Dependencies
    MissingDependency = Class.new(StandardError)

    # Updates ENV["PATH"] with the current mise tool paths.
    #
    # This ensures the Ruby process can access newly installed tools
    # without requiring a restart.
    def self.refresh_env_path!
      return unless tool_version_manager_available?

      sh = KDK::Shellout
        .new('mise', 'exec', '--', 'printenv', 'PATH')
        .execute(display_output: false)

      raise "Command failed: #{sh.command}" unless sh.success?

      ENV['PATH'] = sh.read_stdout

      nil
    end

    # Is Homebrew available?
    #
    # @return boolean
    def self.homebrew_available?
      Utils.executable_exist?('brew')
    end

    # Is MacPorts available?
    #
    # @return boolean
    def self.macports_available?
      Utils.executable_exist?('port')
    end

    # Is Debian / Ubuntu APT available?
    #
    # @return boolean
    def self.linux_apt_available?
      Utils.executable_exist?('apt')
    end

    # Is asdf is available and correctly setup?
    #
    # @return boolean
    def self.asdf_available?
      return false if config.asdf.opt_out?

      Utils.executable_exist?('asdf') || ENV.values_at('ASDF_DATA_DIR', 'ASDF_DIR').compact.any?
    end

    # Is tool version manager available?
    #
    # @return [Boolean]
    def self.tool_version_manager_available?
      config.tool_version_manager.enabled? && Utils.executable_exist?('mise')
    end

    def self.bundler_loaded?
      defined? Bundler
    end

    def self.config
      KDK.config
    end
  end
end
