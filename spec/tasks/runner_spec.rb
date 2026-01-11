# frozen_string_literal: true

RSpec.describe 'rake runner:setup', :hide_output do
  include ShelloutHelper

  let(:runner_binary_path) { File.join(KDK.config.kdk_root, 'khulnasoft-runner') }
  let(:config_path) { File.join(KDK.config.kdk_root, 'khulnasoft-runner-config.yml') }
  let(:download_shellout) { kdk_shellout_double(success?: true) }
  let(:no_token_shellout) { kdk_shellout_double(success?: true, read_stdout: "\n") }
  let(:existing_token_shellout) { kdk_shellout_double(success?: true, read_stdout: "existing_token\n") }
  let(:new_token_shellout) { kdk_shellout_double(success?: true, read_stdout: "new_token\n") }
  let(:failed_shellout) { kdk_shellout_double(success?: false) }

  before(:all) do
    Rake.application.rake_require('tasks/runner')
  end

  before do
    allow(download_shellout).to receive(:execute).and_return(download_shellout)
    allow(no_token_shellout).to receive(:execute).and_return(no_token_shellout)
    allow(existing_token_shellout).to receive(:execute).and_return(existing_token_shellout)
    allow(new_token_shellout).to receive(:execute).and_return(new_token_shellout)
    allow(failed_shellout).to receive(:execute).and_return(failed_shellout)

    allow(KDK.config).to receive_message_chain(:runner, :enabled).and_return(false)
    allow(KDK.config).to receive(:kdk_root).and_return('/path/to/kdk')
    allow(KDK.config).to receive_message_chain(:khulnasoft, :dir).and_return('/path/to/khulnasoft')
    allow(KDK.config).to receive(:bury!)
    allow(KDK.config).to receive(:save_yaml!)
    allow(KDK::Machine).to receive_messages(supported?: true, package_platform: 'macos-amd64')
    allow_any_instance_of(KDK::Command::Reconfigure).to receive(:run)
    allow(File).to receive_messages(exist?: false, executable?: false)
    allow(File).to receive(:chmod)
    allow(KDK::Output).to receive(:prompt).and_return('n')

    allow(KDK::Shellout).to receive(:new).and_call_original
    allow(KDK::Shellout).to receive(:new).with(['curl', '-L', '--output', runner_binary_path, anything]).and_return(download_shellout)
    allow(KDK::Shellout).to receive(:new).with(['bundle', 'exec', 'rails', 'runner', anything], chdir: '/path/to/khulnasoft').and_return(no_token_shellout)
  end

  context 'when platform is not supported' do
    before do
      allow(KDK::Machine).to receive(:supported?).and_return(false)
    end

    it 'skips runner setup' do
      expect(KDK::Output).to receive(:info).with('Skipping runner setup as this platform is not supported.')
      expect(KDK::Shellout).not_to receive(:new)

      Rake::Task['runner:setup'].execute
    end
  end

  context 'when runner is already enabled' do
    before do
      allow(KDK.config).to receive_message_chain(:runner, :enabled).and_return(true)
    end

    it 'skips enabling runner' do
      expect(KDK.config).not_to receive(:bury!).with('runner.enabled', true)

      Rake::Task['runner:setup'].execute
    end
  end

  context 'when runner is not enabled' do
    it 'enables runner in config' do
      expect(KDK.config).to receive(:bury!).with('runner.enabled', true)

      Rake::Task['runner:setup'].execute
    end
  end

  context 'when downloading binary' do
    context 'when binary already exists and is executable' do
      before do
        allow(File).to receive(:exist?).with(runner_binary_path).and_return(true)
        allow(File).to receive(:executable?).with(runner_binary_path).and_return(true)
      end

      it 'skips download' do
        expect(KDK::Output).to receive(:info).with('Runner binary already exists, skipping download')
        expect(KDK::Shellout).not_to receive(:new).with(['curl', '-L', '--output', runner_binary_path, anything])

        Rake::Task['runner:setup'].execute
      end

      it 'does not save binary path to config' do
        expect(KDK.config).not_to receive(:bury!).with('runner.bin', anything)

        Rake::Task['runner:setup'].execute
      end
    end

    context 'when binary does not exist' do
      it 'downloads and configures binary' do
        expect(KDK::Output).to receive(:info).with('Downloading runner binary...')
        expect(KDK::Shellout).to receive(:new).with(['curl', '-L', '--output', runner_binary_path, anything]).and_return(download_shellout)
        expect(KDK::Output).to receive(:success).with('Runner binary downloaded')
        expect(KDK.config).to receive(:bury!).with('runner.bin', runner_binary_path)
        expect(KDK.config).to receive(:save_yaml!)

        Rake::Task['runner:setup'].execute
      end
    end

    context 'when download fails' do
      before do
        allow(KDK::Shellout).to receive(:new).with(['curl', '-L', '--output', runner_binary_path, anything]).and_return(failed_shellout)
      end

      it 'aborts with error message' do
        expect(KDK::Output).to receive(:abort).with('Failed to download runner binary')

        Rake::Task['runner:setup'].execute
      end
    end
  end

  context 'when setting up runner token' do
    context 'when existing runner is found' do
      before do
        allow(KDK::Shellout).to receive(:new).with(['bundle', 'exec', 'rails', 'runner', anything], chdir: '/path/to/khulnasoft').and_return(existing_token_shellout)
      end

      it 'shows success message and does not prompt user' do
        expect(KDK::Output).to receive(:success).with('Runner with khulnasoft--duo tag already exists')
        expect(KDK::Output).not_to receive(:prompt)

        Rake::Task['runner:setup'].execute
      end

      it 'does not run reconfigure' do
        expect_any_instance_of(KDK::Command::Reconfigure).not_to receive(:run)

        Rake::Task['runner:setup'].execute
      end
    end

    context 'when existing runner is not found' do
      it 'prompts user to create runner' do
        expect(KDK::Output).to receive(:prompt).with('Create new runner with khulnasoft--duo tag? [y/N]', raise_interrupt: true)

        Rake::Task['runner:setup'].execute
      end

      it 'shows warning about config update' do
        expect(KDK::Output).to receive(:warn).with("Creating runner will update #{config_path}")

        Rake::Task['runner:setup'].execute
      end

      context 'when user declines' do
        before do
          allow(KDK::Output).to receive(:prompt).and_return('n')
        end

        it 'does not create runner' do
          expect(KDK::Shellout).to receive(:new).once.with(
            ['bundle', 'exec', 'rails', 'runner', anything],
            chdir: '/path/to/khulnasoft'
          ).and_return(no_token_shellout)

          Rake::Task['runner:setup'].execute
        end

        it 'does not run reconfigure' do
          expect_any_instance_of(KDK::Command::Reconfigure).not_to receive(:run)

          Rake::Task['runner:setup'].execute
        end
      end

      context 'when user confirms' do
        before do
          allow(KDK::Output).to receive(:prompt).and_return('y')
          allow(KDK::Shellout).to receive(:new).with(['bundle', 'exec', 'rails', 'runner', anything], chdir: '/path/to/khulnasoft').and_return(no_token_shellout, new_token_shellout)
        end

        it 'saves token to config and shows success message' do
          expect(KDK.config).to receive(:bury!).with('runner.token', 'new_token')
          expect(KDK.config).to receive(:save_yaml!)
          expect(KDK::Output).to receive(:success).with('Runner created with khulnasoft--duo tag and token saved to kdk.yml')

          Rake::Task['runner:setup'].execute
        end

        it 'runs reconfigure' do
          expect_any_instance_of(KDK::Command::Reconfigure).to receive(:run)

          Rake::Task['runner:setup'].execute
        end

        context 'when config file exists' do
          let(:backup_mock) { instance_double(KDK::Backup) }

          before do
            allow(File).to receive(:exist?).with(config_path).and_return(true)
            allow(KDK::Backup).to receive(:new).with(config_path).and_return(backup_mock)
            allow(backup_mock).to receive(:backup!)
          end

          it 'creates backup' do
            expect(KDK::Backup).to receive(:new).with(config_path).and_return(backup_mock)
            expect(backup_mock).to receive(:backup!)

            Rake::Task['runner:setup'].execute
          end
        end

        context 'when config file does not exist' do
          before do
            allow(File).to receive(:exist?).with(config_path).and_return(false)
          end

          it 'does not create backup' do
            expect(KDK::Backup).not_to receive(:new)

            Rake::Task['runner:setup'].execute
          end
        end

        context 'when runner creation fails' do
          before do
            allow(KDK::Shellout).to receive(:new).with(['bundle', 'exec', 'rails', 'runner', anything], chdir: '/path/to/khulnasoft').and_return(no_token_shellout, failed_shellout)
          end

          it 'aborts with error message' do
            expect(KDK::Output).to receive(:abort).with('Failed to create runner')

            Rake::Task['runner:setup'].execute
          end
        end
      end
    end
  end
end
