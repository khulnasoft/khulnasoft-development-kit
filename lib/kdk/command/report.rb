# frozen_string_literal: true

require 'erb'
require 'shellwords'
require 'etc'

module KDK
  module Command
    class Report < BaseCommand
      help 'Generate a detailed support issue to get help with troubleshooting'

      REPORT_TEMPLATE_PATH = 'lib/support/files/report_template.md.erb'

      ENV_VARS = %w[
        PATH LANG LANGUAGE LC_ALL LDFLAGS CPPFLAGS PKG_CONFIG_PATH
        LIBPCREDIR RUBY_CONFIGURE_OPTS
      ].freeze
      LOG_VINTAGE_AGE = 60 * 60 * 24 * 14 # 14 days in seconds

      REPOSITORY_NAMES = %w[kdk gitaly khulnasoft].freeze
      NEW_ISSUE_URL = 'https://github.com/khulnasoft/khulnasoft-development-kit/issues/new?issue[label]=~Category:KDK'
      LABELING = '/label ~type::bug ~bug::functional ~Category:KDK ~kdk-report ~"group::development tooling" ~"development-tooling::support request"'
      COPY_COMMANDS = [
        'pbcopy', # macOS
        'xclip -selection clipboard', # Linux
        'xsel --clipboard --input', # Linux
        'wl-copy' # Wayland
      ].freeze

      OPEN_COMMANDS = [
        'open', # macOS
        'xdg-open' # Linux
      ].freeze

      def run(_ = [])
        template_path = KDK.root.join(REPORT_TEMPLATE_PATH)
        KDK::Output.info('We are collecting report details, this might take a minute ...')

        # Create variables for the template
        report_json = {
          os_name: os_name,
          arch: arch,
          ruby_version: ruby_version,
          kdk_version: kdk_version,
          package_manager: package_manager,
          env_variables: env_variables,
          kdk_config: kdk_config,
          kdk_doctor: kdk_doctor,
          gem_env: gem_env,
          bundle_env: bundle_env,
          network_information: network_information,
          logs: logs,
          git_repositories: git_repositories,
          date_time: date_time
        }

        # Render the template
        renderer = Templates::ErbRenderer.new(template_path, report_json: report_json)
        report_content = renderer.render_to_string

        KDK::Output.puts report_content
        open_browser
        copy_clipboard(report_content)

        KDK::Output.info('This report has been copied to your clipboard.')
        KDK::Output.info('We opened the browser with a new issue, please paste this report from your clipboard into the description.')

        true
      end

      def package_manager
        if KDK.config.tool_version_manager.enabled?
          "mise-en-place #{shellout('mise --version')}"
        else
          'mise is not enabled.'
        end
      end

      def env_variables
        ENV_VARS.map do |variable|
          value = ENV.fetch(variable, nil)&.gsub(Dir.home, '$HOME')
          "#{variable}=#{value}"
        end.join("\n")
      end

      def kdk_yml_exists?
        File.exist?(KDK::Config::FILE)
      end

      def kdk_config
        return 'No KDK configuration found.' unless kdk_yml_exists?

        ConfigRedactor.redact(config.dump!(user_only: true)).to_yaml
      end

      def kdk_doctor
        output = KDK::OutputBuffered.new

        begin
          KDK::Command::Doctor.new(out: output).run
        rescue UserInteractionRequired
          # Swallow exception to prevent early exit
        end

        redact_home(output.dump.chomp)
      end

      def gem_env
        redact_home(shellout('gem env'))
      end

      def bundle_env
        redact_home(shellout('bundle env'))
      end

      def network_information
        shellout('lsof -iTCP -sTCP:LISTEN').gsub(Etc.getpwuid.name, '$USER')
      end

      def logs
        log_file_paths.each_with_object({}) do |log_file_path, logs|
          next if Time.now - File.stat(log_file_path).mtime > LOG_VINTAGE_AGE

          log_report = Support::Rake::TaskLogger.new(log_file_path).tail(only_with_errors: true)
          next unless log_report

          logs[key_name(log_file_path)] = redact_home(log_report)
        end
      end

      def log_file_paths
        Dir['log/kdk/rake-latest/*.log'] + Dir['log/*/current'] + Dir['khulnasoft/log/*.log'] - %w[khulnasoft/log/development.log khulnasoft/log/sidekiq.log]
      end

      def key_name(log_file_path)
        key_name_base = File.basename(log_file_path, '.log')

        if log_file_path.match?(%r{^log/([^/]+)/current$})
          "kdk/#{File.basename(File.dirname(log_file_path))}"
        elsif log_file_path.include?('khulnasoft/log/')
          "khulnasoft/#{key_name_base}"
        else
          key_name_base
        end
      end

      def git_repositories
        REPOSITORY_NAMES.each_with_object({}) do |repo_name, repositories|
          repositories[repo_name] = {
            git_status: git_status(repo_name),
            git_head: git_head(repo_name)
          }
        end
      end

      def date_time
        Time.now.strftime('%d/%m/%Y %H:%M:%S %Z')
      end

      def git_status(repo_name)
        command = repo_name == 'kdk' ? 'git status' : "cd #{repo_name} && git status"
        shellout(command)
      end

      def git_head(repo_name)
        command = repo_name == 'kdk' ? 'git show HEAD' : "cd #{repo_name} && git show HEAD"
        shellout(command)[/.*/]
      end

      def shellout(cmd, **args)
        KDK::Shellout.new(cmd, **args).run
      rescue StandardError => e
        "Failed to execute shell command: #{e.message}"
      end

      def redact_home(message)
        message.gsub(Dir.home, ConfigRedactor::HOME_REDACT_WITH)
      end

      def copy_clipboard(content)
        (command = find_command(COPY_COMMANDS)) ||
          abort('Could not automatically copy message to clipboard. Please copy the output manually.')

        IO.popen(::Shellwords.split(command), 'w') do |pipe|
          pipe.print(content)
        end
      end

      def open_browser
        (command = find_command(OPEN_COMMANDS)) ||
          abort('Could not automatically open browser. Please open the URL manually.')

        url = URI(NEW_ISSUE_URL)
        url.query = query

        system(*Shellwords.split(command), url)
      end

      def query
        URI.encode_www_form(
          'issue[issue_type]': :incident,
          'issue[confidential]': true,
          'issue[title]': "Report: ENTER A TITLE FOR YOUR REPORT",
          'issue[description]': description
        )
      end

      def description
        <<~MARKDOWN
          #{LABELING}

          <!-- Please paste the report from your clipboard below here. -->
        MARKDOWN
      end

      def find_command(list)
        list.find { |command| Utils.find_executable(command.split.first) }
      end

      private

      def os_name
        shellout('uname -moprsv')
      end

      def arch
        shellout('arch')
      end

      def ruby_version
        shellout('ruby --version')
      end

      def kdk_version
        shellout('git rev-parse --short HEAD')
      end
    end
  end
end
