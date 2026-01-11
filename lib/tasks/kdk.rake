# frozen_string_literal: true

namespace :kdk do
  migrations = %w[
    migrate:update_telemetry_settings
    migrate:mise
    migrate:mise_trust
  ]

  desc 'Run migration related to KDK setup'
  task migrate: migrations

  namespace :migrate do
    desc 'Update settings to turn on telemetry for KhulnaSoft team members (determined by @khulnasoft.com email in git config) and anonymize usernames for all users'
    task :update_telemetry_settings do
      telemetry_enabled = KDK.config.telemetry.enabled
      is_team_member = KDK::Telemetry.team_member?
      should_update = telemetry_enabled || is_team_member

      if should_update
        KDK::Output.info('Telemetry has been automatically enabled for you as a KhulnaSoft team member.') if !telemetry_enabled && is_team_member

        KDK::Telemetry.update_settings('y')
      end
    end

    desc 'Prompts KhulnaSoft team members to migrate from asdf to mise if asdf is still in use'
    task :mise do
      next unless KDK::Telemetry.team_member?
      next if KDK.config.asdf.opt_out? || KDK.config.tool_version_manager.enabled?
      next unless KDK::ReminderHelper.should_run_reminder?('mise_migration')

      update_message = <<~MESSAGE
        We're no longer supporting asdf in KDK.

        You can still use asdf if you need to, for example outside of KDK. But it's no longer supported in KDK and won't be maintained going forward.

        Mise provides better supply chain security while running faster and avoiding the dependency installation problems that we had to manually fix with asdf.

        To migrate, run:
          kdk update
      MESSAGE

      KDK::Output.warn(update_message)
      KDK::Output.puts

      unless KDK::Output.interactive?
        KDK::Output.info('Skipping mise migration prompt in non-interactive environment.')
        next
      end

      if KDK::Output.prompt('Would you like it to switch to mise now? [y/N]').match?(/\Ay(?:es)*\z/i)
        KDK::Output.info('Great! Running the mise migration now..')
        KDK::Execute::Rake.new('mise:migrate').execute_in_kdk
      else
        KDK::Output.info("No worries. We'll remind you again in 5 days.")
        KDK::ReminderHelper.update_reminder_timestamp!('mise_migration')
      end
    end

    desc 'Trust the .mise.toml configuration'
    task :mise_trust do
      next unless KDK.config.tool_version_manager.enabled?

      cache_file = File.join(KDK.config.kdk_root, '.cache', '.mise_trusted')
      next if File.exist?(cache_file)

      mise_config = File.join(KDK.config.kdk_root, '.mise.toml')
      sh = KDK::Shellout.new("mise trust #{mise_config}").execute
      if sh.success?
        FileUtils.mkdir_p(File.dirname(cache_file))
        FileUtils.touch(cache_file)
      end
    end
  end

  desc 'Configure shell to enable autocompletion'
  task :shell_completion do
    shell_completion = KDK.config.kdk.shell_completion?
    ShellCompletion.new(shell_completion).execute
  end
end

class ShellCompletion
  MARKER = '# Added by KDK'

  def initialize(shell_completion_enabled)
    @shell_completion_enabled = shell_completion_enabled
    @shell_name = File.basename(ENV['SHELL'] || '')
    @profile_paths = {
      'bash' => "#{Dir.home}/.bashrc",
      'zsh' => "#{Dir.home}/.zshrc"
    }
    @kdk_completion_path = "#{KDK.root}/support/completions/kdk.bash"
  end

  def execute
    shell_profile_path = (@profile_paths[@shell_name] if @profile_paths.include?(@shell_name) && File.exist?(@profile_paths[@shell_name]))

    unless shell_profile_path
      display_manual_instructions
      return
    end

    shell_profile_content = File.read(shell_profile_path)
    updated_shell_profile_content = updated_shell_profile_content(shell_profile_content)

    if updated_shell_profile_content == shell_profile_content
      KDK::Output.info(<<~MSG)
        Shell completion is already #{@shell_completion_enabled ? 'enabled' : 'disabled'} in #{shell_profile_path}
        Please source your shell profile to apply changes or restart your shell:
        To source your shell profile: source #{shell_profile_path}
      MSG
      return
    end

    update_shell_profile(shell_profile_path, updated_shell_profile_content)
  end

  private

  def display_manual_instructions
    case @shell_name
    when 'bash'
      KDK::Output.warn(<<~MSG
        Cannot find shell profile for your shell #{@shell_name}.
        Please add the following line to your shell profile and restart shell:
        source "#{@kdk_completion_path}"
      MSG
                      )
    when 'zsh'
      KDK::Output.warn(<<~MSG
        Cannot find shell profile for your shell #{@shell_name}.
        Please add the following line to your shell profile and restart shell:
        autoload bashcompinit
        bashcompinit
        source "#{@kdk_completion_path}"
      MSG
                      )
    else
      KDK::Output.warn(<<~MSG
        Unsupported shell: #{@shell_name}.
        Auto completion is supported only for bash or zsh.
      MSG
                      )
    end
  end

  def updated_shell_profile_content(shell_profile_content)
    pattern = /#{MARKER}\n(?:\s*autoload bashcompinit\r?\n\s*bashcompinit\r?\n)?\s*source "#{Regexp.escape(@kdk_completion_path)}"\n/

    if @shell_completion_enabled
      if shell_profile_content.match?(pattern)
        shell_profile_content.gsub(pattern, completion_block)
      else
        shell_profile_content + "\n#{completion_block}"
      end
    else
      shell_profile_content.gsub(pattern, '')
    end
  end

  def completion_block
    case @shell_name
    when 'bash'
      %(#{MARKER}\nsource "#{@kdk_completion_path}"\n)
    when 'zsh'
      %(#{MARKER}\nautoload bashcompinit\nbashcompinit\nsource "#{@kdk_completion_path}"\n)
    end
  end

  def update_shell_profile(shell_profile_path, content)
    backup_path = "#{shell_profile_path}.#{Time.now.strftime('%Y%m%d%H%M%S')}.bak"
    FileUtils.cp(shell_profile_path, backup_path)

    File.write(shell_profile_path, content)

    action = @shell_completion_enabled ? 'enabled' : 'disabled'
    KDK::Output.info("Backup of your shell profile created at: #{backup_path}")
    KDK::Output.success(<<~MSG
      Shell completion #{action} in #{shell_profile_path}
      Please source your shell profile to apply changes or restart your shell:
      To source your shell profile: source #{shell_profile_path}
    MSG
                       )
  rescue StandardError => e
    KDK::Output.error("Failed to update #{shell_profile_path}: #{e.message}")
  end
end
