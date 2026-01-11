# frozen_string_literal: true

# Utility functions that are absent from Ruby standard library
module Utils
  # Search on PATH or default locations for provided binary and return its fullpath
  #
  # @param [String] binary name
  # @return [String] full path to the binary file
  def self.find_executable(binary)
    executable_file = proc { |name| next name if File.file?(name) && File.executable?(name) }

    # Retrieve PATH from ENV or use a fallback
    path = ENV['PATH']&.split(File::PATH_SEPARATOR) || %w[/usr/local/bin /usr/bin /bin]

    # check binary against each PATH
    path.each do |dir|
      file = File.expand_path(binary, dir)

      return file if executable_file.call(file)
    end

    nil
  end

  # If enabled, use mise to find an executable.
  #
  # Otherwise, fall back to the default `find_executable` logic.
  def self.executable_exist_via_tooling_manager?(binary)
    if KDK::Dependencies.tool_version_manager_available?
      KDK::Shellout.new(%W[mise which #{binary}]).execute(display_output: false).success?
    else
      executable_exist?(binary)
    end
  end

  # Check whether provided binary name exists on PATH or default locations
  #
  # @param [String] binary name
  def self.executable_exist?(name)
    !!find_executable(name)
  end

  # Prefix +cmd+ with tool version manager specific execute command.
  #
  # @param [Array<String>] command strings
  def self.prefix_command(*cmd)
    cmd = %w[mise exec --] + cmd if KDK::Dependencies.tool_version_manager_available?

    cmd
  end

  def self.format_duration(seconds)
    return "#{(seconds * 1000).floor}ms" if seconds < 1
    return "#{seconds.round}s" if seconds < 60

    "#{(seconds / 60).floor}m #{seconds.round % 60}s"
  end

  def self.precompiled_ruby?
    RbConfig::CONFIG['configure_args'].to_s.include?('KHULNASOFT_PRECOMPILED=1')
  end
end
