# frozen_string_literal: true

module KDK
  class ToolVersionsUpdater
    MINIMUM_MISE_VERSION = '2025.12.9'
    COMBINED_TOOL_VERSIONS_FILE = '.combined-tool-versions'
    RUBY_PATCHES = {
      '3.2.9' => 'https://github.com/khulnasoft/khulnasoft-build-images/-/raw/d95e4efae87d5e3696f22d12a6c4e377a22f3c95/patches/ruby/3.2/thread-memory-allocations.patch',
      '3.3.10' => 'https://github.com/khulnasoft/khulnasoft-build-images/-/raw/e1be2ad5ff2a0bf0b27f86ef75b73824790b4b26/patches/ruby/3.3/thread-memory-allocations.patch',
      '3.4.3' => 'https://github.com/khulnasoft/khulnasoft-build-images/-/raw/d077c90c540ac99ae75c396b91dcfcb136281059/patches/ruby/3.4/thread-memory-allocations.patch'
    }.freeze

    def self.enabled_services
      # Cache the results of enabled services,
      @enabled_services ||= (KDK::Services.enabled + KDK::Services.legacy.select(&:enabled?)).map(&:name)
      # but return a copy each time to avoid side-effects.
      @enabled_services.dup
    end

    def default_version_for(tool)
      tool_versions[tool]&.first
    end

    def run
      return skip_message unless should_update?

      if KDK::Dependencies.tool_version_manager_available?
        update_mise!
        check_minimum_mise_version!
      end

      tool_versions = collect_tool_versions
      configure_env(tool_versions)
      write_combined_file(tool_versions)
      install_tools(tool_versions)
    ensure
      cleanup
    end

    private

    def expected_mise_version
      @expected_mise_version ||= File.read(KDK.root.join('.mise-version')).strip
    end

    def should_update?
      KDK.config.tool_version_manager.enabled?
    end

    def skip_message
      KDK::Output.info('Skipping tool versions update since mise is not enabled')
    end

    def mise_version_output
      @mise_version_output ||= begin
        output = KDK::Shellout.new(%w[mise version --json]).execute(display_output: false).read_stdout
        JSON.parse(output)
      rescue Errno::ENOENT, JSON::ParserError
        {}
      end
    end

    def current_mise_version
      mise_version_output['version']&.split&.first
    end

    def mise_update_command
      if KDK::Machine.macos?
        'brew update && brew upgrade mise'
      elsif KDK::Machine.linux?
        'apt update && apt upgrade mise'
      end
    end

    def mise_update_required?
      return false unless current_mise_version

      begin
        current_version = Gem::Version.new(current_mise_version)
        expected_version = Gem::Version.new(expected_mise_version)

        current_version < expected_version
      rescue ArgumentError
        false
      end
    end

    def update_mise!
      unless mise_update_required?
        KDK::Output.info("mise is already at version #{current_mise_version}, skipping update")
        return
      end

      KDK::Output.info('Attempting to update mise')

      update_result = KDK::Shellout.new(%w[mise self-update -y]).execute(display_error: false)
      unless update_result.success?
        KDK::Output.info('mise self-update failed, attempting to update via package manager')
        update_result = KDK::Shellout.new(mise_update_command).execute(display_output: false)
      end

      if update_result.success?
        KDK::Output.info('mise update successful')
      else
        KDK::Output.info('mise update unsuccessful. Please manually update mise to the latest version')
      end
    end

    def check_minimum_mise_version!
      @mise_version_output = nil
      return unless current_mise_version

      current_version = Gem::Version.new(current_mise_version)
      minimum_version = Gem::Version.new(MINIMUM_MISE_VERSION)
      raise UserInteractionRequired, "You're running an old version of mise (#{current_version}). Please upgrade to version #{minimum_version} or higher." if current_version < minimum_version
    rescue ArgumentError
    end

    def collect_tool_versions
      git_fetch_version_files

      # Get all service names in the enabled list and include the required ones that are missing.
      service_names = self.class.enabled_services
      service_names.push('khulnasoft', 'khulnasoft-shell')

      services = []
      service_names.each do |name|
        config_key = name.tr('-', '_')
        repo_url = KDK.config.repositories[config_key]

        services << [name, repo_url, config_key] if repo_url
      end

      KDK::Output.info("Found #{services.size} services with repositories")

      threads = services.map do |name, repo_url, config_key|
        Thread.new do
          config = KDK.config[config_key]
          version = get_version(config)

          Thread.current[:tools] = fetch_service_tool_versions(name, repo_url, version)
        end
      end

      threads << Thread.new do
        Thread.current[:tools] = root_tool_versions
      end

      threads
        .flat_map { |thread| thread.join[:tools] }
        .select { |x| x }
        .group_by(&:first)
        .transform_values { |x| x.flat_map(&:last).uniq }
    end

    def root_tool_versions
      path = KDK.root.join('.tool-versions')

      parse_tool_versions(File.read(path))
    end

    def get_version(config)
      return 'main' unless config
      return config.__version if config.respond_to?(:__version) && config.__version
      return config.default_branch if config.respond_to?(:default_branch) && config.default_branch

      'main'
    end

    def git_fetch_version_files
      branch_or_commit = KDK.config.khulnasoft.default_branch
      KDK::Shellout.new("git fetch origin #{branch_or_commit}", chdir: KDK.config.khulnasoft.dir).execute
      KDK::Shellout.new("git checkout FETCH_HEAD -- '*_VERSION'", chdir: KDK.config.khulnasoft.dir).execute
    end

    def http_get(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def parse_tool_versions(content)
      content.each_line.flat_map do |line|
        line = line.split('#', 2).first.strip
        next if line.empty?

        tool, *version_numbers = line.split
        version_numbers.map { |version| [tool, version] }
      end
    end

    def fetch_service_tool_versions(name, repo_url, version_or_branch)
      path = repo_url.sub('.git', '')
      url = "#{path}/-/raw/#{version_or_branch}/.tool-versions"

      response = http_get(url)

      if response.nil?
        KDK::Output.debug("Failed to fetch .tool-versions for '#{name}' from #{repo_url}")
        return nil
      end

      parse_tool_versions(response)
    end

    def write_combined_file(tool_versions)
      combined_content = tool_versions.filter_map do |tool, versions|
        "#{tool} #{versions.join(' ')}"
      end.join("\n").concat("\n")

      File.write(COMBINED_TOOL_VERSIONS_FILE, combined_content)
      KDK::Output.debug("Combined tool versions content:\n#{combined_content}")
    end

    def configure_env(tool_versions)
      rust_version = tool_versions['rust']&.first

      if KDK.config.tool_version_manager.enabled?
        ENV['MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES'] = COMBINED_TOOL_VERSIONS_FILE
        ENV['MISE_RUST_VERSION'] = rust_version if rust_version
      end

      ENV['RUST_WITHOUT'] = 'rust-docs' if rust_version
    end

    def khulnasoft_ruby_plugin_installed?
      result = KDK::Shellout.new(%w[mise plugins ls --urls]).execute(display_output: false)
      return false unless result.success?

      output = result.read_stdout

      ruby_line = output.lines.find { |line| line.strip.start_with?('ruby') }
      return false unless ruby_line

      ruby_line.include?('https://github.com/khulnasoft/quality/tooling/asdf-khulnasoft-ruby')
    end

    def install_tools(tool_versions)
      if KDK.config.tool_version_manager.enabled? && !khulnasoft_ruby_plugin_installed?
        KDK::Output.info('Installing asdf-khulnasoft-ruby plugin...')
        KDK::Shellout.new(%w[mise plugins install --force ruby https://github.com/khulnasoft/quality/tooling/asdf-khulnasoft-ruby]).execute
      end

      install_rust(tool_versions['rust'])

      threads = []
      threads << Thread.new { install_ruby(tool_versions['ruby']) }
      threads << Thread.new { install_node(tool_versions['nodejs']) }

      threads.each(&:join)

      install_remaining_tools

      KDK::Output.success('Successfully updated tool versions!')
    rescue StandardError => e
      KDK::Output.error("Failed to update tool versions: #{e.message}")
    end

    def install_rust(versions)
      return if versions.nil? || versions.empty?

      version = versions.first
      run_install('rust', version)
    end

    def install_ruby(versions)
      return if versions.nil? || versions.empty?

      KDK::Output.debug('Using precompiled Ruby binaries') if KDK.config.kdk.use_precompiled_ruby?

      versions.each do |version|
        ENV['MISC_RUBY_APPLY_PATCHES'] = RUBY_PATCHES[version] if RUBY_PATCHES[version]
        run_install('ruby', version)
      end
    end

    def install_node(versions)
      return if versions.nil? || versions.empty?

      versions.each do |version|
        run_install('nodejs', version)
      end
    end

    def install_remaining_tools
      run_install
    end

    def run_install(tool = nil, version = nil)
      # Unset MAKELEVEL because Postgres cannot install when this variable is present
      cmd = 'env -u MAKELEVEL mise install -y'
      cmd = "#{cmd} #{tool} #{version}" if tool && version

      KDK::Shellout.new(cmd).execute
    end

    def cleanup
      FileUtils.rm_f(COMBINED_TOOL_VERSIONS_FILE)

      if KDK.config.tool_version_manager.enabled?
        ENV.delete('MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES')
        ENV.delete('MISE_RUST_VERSION')
      end

      ENV.delete('RUST_WITHOUT')
    end

    def raw_tool_versions_lines
      KDK.root.glob('{.tool-versions,{*,*/*}/.tool-versions}').each_with_object([]) do |path, lines|
        lines.concat(File.readlines(path))
      end
    end

    def tool_versions
      @tool_versions ||= raw_tool_versions_lines.each_with_object({}) do |line, all|
        found_tool = line.chomp.match(/\A(?<name>\w+) (?<versions>[\d. ]+)\z/)
        next unless found_tool

        new_versions = found_tool[:versions].split
        all[found_tool[:name]] = (all[found_tool[:name]] || []) | new_versions
      end
    end
  end
end
