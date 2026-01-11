# frozen_string_literal: true

RSpec.describe 'rake kdk:migrate' do
  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  it 'invokes its dependencies' do
    expect(task.prerequisites).to eq(%w[migrate:update_telemetry_settings migrate:mise migrate:mise_trust])
  end
end

RSpec.describe 'rake kdk:migrate:update_telemetry_settings' do
  let(:enabled) { false }
  let(:is_team_member) { false }
  let(:username) { 'telemetry_user' }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    stub_kdk_yaml(<<~YAML)
      telemetry:
        enabled: #{enabled}
        username: #{username.inspect}
    YAML

    allow(KDK::Telemetry).to receive(:team_member?).and_return(is_team_member)
    allow(KDK.config).to receive(:save_yaml!)
  end

  context 'when telemetry is disabled' do
    let(:enabled) { false }

    context 'and user is not a KhulnaSoft team member' do
      it 'does nothing' do
        expect(KDK::Telemetry).not_to receive(:update_settings)

        task.invoke
      end
    end

    context 'and user is a team member' do
      let(:is_team_member) { true }

      it 'enables telemetry' do
        expect(KDK::Telemetry).to receive(:update_settings).with('y')
        expect(KDK::Output).to receive(:info).with('Telemetry has been automatically enabled for you as a KhulnaSoft team member.')

        task.invoke
      end
    end
  end

  context 'when telemetry is enabled and username is not anonymized' do
    let(:enabled) { true }
    let(:generated_username) { SecureRandom.hex }

    before do
      allow(SecureRandom).to receive(:hex).and_return(generated_username)
    end

    it 'anonymizes the username' do
      expect { task.invoke }.to output(/Telemetry username has been anonymized./).to_stdout
      expect(KDK.config.telemetry.username).not_to eq(username)
      expect(KDK.config.telemetry.username).to match(/^\h{32}$/)
    end
  end
end

RSpec.describe 'rake kdk:migrate:mise' do
  let(:asdf_opt_out) { false }
  let(:mise_enabled) { false }
  let(:is_team_member) { true }
  let(:should_run_reminder) { true }
  let(:is_interactive) { true }
  let(:user_response) { 'n' }
  let(:rake_instance) { instance_double(KDK::Execute::Rake) }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    allow(KDK.config).to receive_message_chain(:asdf, :opt_out?).and_return(asdf_opt_out)
    allow(KDK.config).to receive_message_chain(:tool_version_manager, :enabled?).and_return(mise_enabled)
    allow(KDK::Telemetry).to receive(:team_member?).and_return(is_team_member)
    allow(KDK::ReminderHelper).to receive(:should_run_reminder?).with('mise_migration').and_return(should_run_reminder)
    allow(KDK::Output).to receive(:warn)
    allow(KDK::Output).to receive(:puts)
    allow(KDK::Output).to receive(:info)
    allow(KDK::Output).to receive_messages(interactive?: is_interactive, prompt: user_response)
    allow(KDK::Output).to receive(:prompt).and_return(user_response)
    allow(KDK::ReminderHelper).to receive(:update_reminder_timestamp!)
    allow(KDK::Execute::Rake).to receive(:new).with('mise:migrate').and_return(rake_instance)
    allow(rake_instance).to receive(:execute_in_kdk)
  end

  context 'when asdf is opted out' do
    let(:asdf_opt_out) { true }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when mise is already enabled' do
    let(:mise_enabled) { true }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when user is not a KhulnaSoft team member' do
    let(:is_team_member) { false }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when reminder should not run' do
    let(:should_run_reminder) { false }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when migration should be prompted' do
    context 'when environment is not interactive' do
      let(:is_interactive) { false }

      it 'displays info message and skips the migration prompt' do
        expect(KDK::Output).to receive(:info).with('Skipping mise migration prompt in non-interactive environment.')
        expect(KDK::Output).not_to receive(:prompt)

        task.invoke
      end
    end

    context 'when user accepts the migration' do
      let(:user_response) { 'y' }

      it 'runs the migration' do
        expect(KDK::Output).to receive(:prompt).with('Would you like it to switch to mise now? [y/N]')
        expect(KDK::Output).to receive(:info).with('Great! Running the mise migration now..')
        expect(rake_instance).to receive(:execute_in_kdk)

        task.invoke
      end
    end

    context 'when user declines the migration' do
      let(:user_response) { 'n' }

      it 'updates the reminder timestamp' do
        expect(KDK::Output).to receive(:prompt).with('Would you like it to switch to mise now? [y/N]')
        expect(KDK::Output).to receive(:info).with("No worries. We'll remind you again in 5 days.")
        expect(KDK::ReminderHelper).to receive(:update_reminder_timestamp!).with('mise_migration')
        expect(rake_instance).not_to receive(:execute_in_kdk)

        task.invoke
      end
    end
  end
end

RSpec.describe 'rake kdk:migrate:mise_trust' do
  include ShelloutHelper

  let(:mise_enabled) { true }
  let(:cache_file) { File.join(KDK.config.kdk_root, '.cache', '.mise_trusted') }
  let(:mise_config) { File.join(KDK.config.kdk_root, '.mise.toml') }
  let(:shellout_double) { kdk_shellout_double(success?: true) }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    allow(KDK.config).to receive_message_chain(:tool_version_manager, :enabled?).and_return(mise_enabled)
    allow(File).to receive(:exist?).with(cache_file).and_return(false)
    allow(shellout_double).to receive(:execute).and_return(shellout_double)
    allow_kdk_shellout_command("mise trust #{mise_config}").and_return(shellout_double)
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:touch)
  end

  context 'when mise is disabled' do
    let(:mise_enabled) { false }

    it 'skips trusting the configuration' do
      expect_no_kdk_shellout

      task.invoke
    end
  end

  context 'when cache file already exists' do
    before do
      allow(File).to receive(:exist?).with(cache_file).and_return(true)
    end

    it 'skips trusting the configuration' do
      expect_no_kdk_shellout

      task.invoke
    end
  end

  context 'when mise trust should run' do
    context 'when command succeeds' do
      it 'runs mise trust and creates cache file' do
        expect_kdk_shellout_command("mise trust #{mise_config}")
        expect(FileUtils).to receive(:mkdir_p).with(File.dirname(cache_file))
        expect(FileUtils).to receive(:touch).with(cache_file)

        task.invoke
      end
    end

    context 'when command fails' do
      let(:shellout_double) { kdk_shellout_double(success?: false) }

      it 'runs mise trust but does not create cache file' do
        expect_kdk_shellout_command("mise trust #{mise_config}")
        expect(FileUtils).not_to receive(:mkdir_p)
        expect(FileUtils).not_to receive(:touch)

        task.invoke
      end
    end
  end
end

RSpec.describe 'rake kdk:shell_completion' do
  let(:home_dir) { '/home/user' }
  let(:kdk_root) { '/path/to/kdk' }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    allow(KDK.config).to receive_message_chain(:kdk, :shell_completion?).and_return(shell_completion_enabled)
    allow(ENV).to receive(:[]).and_call_original
    allow(Dir).to receive(:home).and_return(home_dir)
    allow(KDK).to receive(:root).and_return(kdk_root)
    allow(KDK::Output).to receive(:success)
    allow(KDK::Output).to receive(:info)
    allow(KDK::Output).to receive(:notice)
    allow(KDK::Output).to receive(:warn)
    allow(KDK::Output).to receive(:error)
    allow(KDK::Output).to receive(:puts)
  end

  context 'with bash' do
    let(:shell_name) { 'bash' }
    let(:shell_profile) { "#{home_dir}/.bashrc" }

    before do
      allow(ENV).to receive(:[]).with('SHELL').and_return("/bin/#{shell_name}")
      allow(File).to receive(:exist?).with(shell_profile).and_return(true)
    end

    context 'when shell_completion is enabled' do
      let(:shell_completion_enabled) { true }

      context 'with no existing completion block in shell profile' do
        let(:shell_profile_content) { "existing content\n" }
        let(:expected_message) do
          <<~MSG
            Shell completion enabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:expected_content) do
          "existing content\n\n# Added by KDK\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
          allow(File).to receive(:write)
          allow(FileUtils).to receive(:cp)
          allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
        end

        it 'adds bash completion block and creates backup' do
          expect(FileUtils).to receive(:cp).with(shell_profile, "#{shell_profile}.20250101120000.bak")
          expect(File).to receive(:write).with(shell_profile, expected_content)

          expect(KDK::Output).to receive(:info).with("Backup of your shell profile created at: #{shell_profile}.20250101120000.bak")
          expect(KDK::Output).to receive(:success).with(expected_message)

          task.invoke
        end
      end

      context 'with existing completion block in shell profile' do
        let(:shell_profile_content) do
          "existing content\n\n# Added by KDK\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        let(:expected_message) do
          <<~MSG
            Shell completion is already enabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
        end

        it 'skips updating the shell profile and backup creation' do
          expect(FileUtils).not_to receive(:cp)
          expect(File).not_to receive(:write)
          expect(KDK::Output).to receive(:info).with(expected_message)

          task.invoke
        end
      end
    end

    context 'when shell_completion is disabled' do
      let(:shell_completion_enabled) { false }

      context 'with existing completion block in shell profile' do
        let(:expected_content) do
          "existing content\n\n"
        end

        let(:expected_message) do
          <<~MSG
            Shell completion disabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:shell_profile_content) do
          "existing content\n\n# Added by KDK\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
          allow(File).to receive(:write)
          allow(FileUtils).to receive(:cp)
          allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
        end

        it 'removes bash completion block and creates backup' do
          expect(FileUtils).to receive(:cp).with(shell_profile, "#{shell_profile}.20250101120000.bak")
          expect(File).to receive(:write).with(shell_profile, expected_content)

          expect(KDK::Output).to receive(:info).with("Backup of your shell profile created at: #{shell_profile}.20250101120000.bak")
          expect(KDK::Output).to receive(:success).with(expected_message)

          task.invoke
        end
      end

      context 'with no existing completion block in shell profile' do
        let(:expected_message) do
          <<~MSG
            Shell completion is already disabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:shell_profile_content) do
          "existing content\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
        end

        it 'skips updating the shell profile and backup creation' do
          expect(FileUtils).not_to receive(:cp)
          expect(File).not_to receive(:write)
          expect(KDK::Output).to receive(:info).with(expected_message)

          task.invoke
        end
      end
    end

    context 'when shell profile does not exist' do
      let(:shell_completion_enabled) { false }
      let(:expected_message) do
        <<~MSG
          Cannot find shell profile for your shell bash.
          Please add the following line to your shell profile and restart shell:
          source "#{kdk_root}/support/completions/kdk.bash"
        MSG
      end

      before do
        allow(File).to receive(:exist?).with(shell_profile).and_return(false)
      end

      it 'displays manual instructions for bash' do
        expect(KDK::Output).to receive(:warn).with(expected_message)
        expect(File).not_to receive(:write)
        expect(FileUtils).not_to receive(:cp)

        task.invoke
      end
    end
  end

  context 'with zsh' do
    let(:shell_name) { 'zsh' }
    let(:shell_profile) { "#{home_dir}/.zshrc" }

    before do
      allow(ENV).to receive(:[]).with('SHELL').and_return("/bin/#{shell_name}")
      allow(File).to receive(:exist?).with(shell_profile).and_return(true)
    end

    context 'when shell_completion is enabled' do
      let(:shell_completion_enabled) { true }

      context 'with no existing completion block in shell profile' do
        let(:shell_profile_content) { "existing content\n" }
        let(:expected_message) do
          <<~MSG
            Shell completion enabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:expected_content) do
          "existing content\n\n# Added by KDK\nautoload bashcompinit\nbashcompinit\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
          allow(File).to receive(:write)
          allow(FileUtils).to receive(:cp)
          allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
        end

        it 'adds zsh completion block with bashcompinit and creates backup' do
          expect(FileUtils).to receive(:cp).with(shell_profile, "#{shell_profile}.20250101120000.bak")
          expect(File).to receive(:write).with(shell_profile, expected_content)
          expect(KDK::Output).to receive(:info).with("Backup of your shell profile created at: #{shell_profile}.20250101120000.bak")
          expect(KDK::Output).to receive(:success).with(expected_message)

          task.invoke
        end
      end

      context 'with existing completion block in shell profile' do
        let(:shell_profile_content) do
          "existing content\n\n# Added by KDK\nautoload bashcompinit\nbashcompinit\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        let(:expected_message) do
          <<~MSG
            Shell completion is already enabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
        end

        it 'skips updating the shell profile and backup creation' do
          expect(FileUtils).not_to receive(:cp)
          expect(File).not_to receive(:write)
          expect(KDK::Output).to receive(:info).with(expected_message)

          task.invoke
        end
      end
    end

    context 'when shell_completion is disabled' do
      let(:shell_completion_enabled) { false }

      context 'with existing completion block in shell profile' do
        let(:expected_content) do
          "existing content\n\n"
        end

        let(:expected_message) do
          <<~MSG
            Shell completion disabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:shell_profile_content) do
          "existing content\n\n# Added by KDK\nautoload bashcompinit\nbashcompinit\nsource \"#{kdk_root}/support/completions/kdk.bash\"\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
          allow(File).to receive(:write)
          allow(FileUtils).to receive(:cp)
          allow(Time).to receive(:now).and_return(Time.new(2025, 1, 1, 12, 0, 0))
        end

        it 'removes zsh completion block and creates backup' do
          expect(FileUtils).to receive(:cp).with(shell_profile, "#{shell_profile}.20250101120000.bak")
          expect(File).to receive(:write).with(shell_profile, expected_content)

          expect(KDK::Output).to receive(:info).with("Backup of your shell profile created at: #{shell_profile}.20250101120000.bak")
          expect(KDK::Output).to receive(:success).with(expected_message)

          task.invoke
        end
      end

      context 'with no existing completion block in shell profile' do
        let(:expected_message) do
          <<~MSG
            Shell completion is already disabled in #{shell_profile}
            Please source your shell profile to apply changes or restart your shell:
            To source your shell profile: source #{shell_profile}
          MSG
        end

        let(:shell_profile_content) do
          "existing content\n"
        end

        before do
          allow(File).to receive(:read).with(shell_profile).and_return(shell_profile_content)
        end

        it 'skips updating the shell profile and backup creation' do
          expect(FileUtils).not_to receive(:cp)
          expect(File).not_to receive(:write)
          expect(KDK::Output).to receive(:info).with(expected_message)

          task.invoke
        end
      end
    end

    context 'when shell profile does not exist' do
      let(:shell_completion_enabled) { false }
      let(:expected_message) do
        <<~MSG
          Cannot find shell profile for your shell zsh.
          Please add the following line to your shell profile and restart shell:
          autoload bashcompinit
          bashcompinit
          source "#{kdk_root}/support/completions/kdk.bash"
        MSG
      end

      before do
        allow(File).to receive(:exist?).with(shell_profile).and_return(false)
      end

      it 'displays manual instructions for zsh' do
        expect(KDK::Output).to receive(:warn).with(expected_message)
        expect(File).not_to receive(:write)
        expect(FileUtils).not_to receive(:cp)

        task.invoke
      end
    end
  end

  context 'with unsupported shell' do
    let(:shell_name) { 'fish' }
    let(:shell_completion_enabled) { true }
    let(:expected_message) do
      <<~MSG
        Unsupported shell: fish.
        Auto completion is supported only for bash or zsh.
      MSG
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SHELL').and_return('/bin/fish')
    end

    it 'displays unsupported shell message and does not modify any files' do
      expect(KDK::Output).to receive(:warn).with(expected_message)
      expect(File).not_to receive(:write)
      expect(FileUtils).not_to receive(:cp)

      task.invoke
    end
  end
end
