# frozen_string_literal: true

RSpec.describe KDK::Command do
    let(:commands) { described_class.command_map }

  context 'with declared available command classes' do
    before do
      commands.each_value do |command_class_proc|
        # KDK::Command::Removed is a special case that does not inherit from BaseCommand
        next if command_class_proc.call == KDK::Command::Removed

        it "expects #{command_class_proc.call} to inherit from KDK::Command::BaseCommand directly or indirectly" do
          command_class = command_class_proc.call

          expect(command_class < KDK::Command::BaseCommand).to be_truthy
        end
      end
    end
  end

  describe '.run' do
    real_commands = commands.select { |_key, block| block.call.name }
    validating_config = real_commands.values.map(&:call).select(&:validate_config?)

    describe 'command invocation' do
      real_commands.each do |command, command_class_proc|
        command_klass = command_class_proc.call

        context "when invoking 'kdk #{command}' from command-line" do
          let(:argv) { [command] }

          it "delegates execution to #{command_klass}" do
            if validating_config.include?(command_klass)
              expect(described_class).to receive(:validate_config!).and_call_original
            else
              expect(described_class).not_to receive(:validate_config!)
            end

            expect_any_instance_of(command_klass).to receive(:run).and_return(true)

            expect { described_class.run(argv) }.to raise_error(SystemExit)
          end
        end
      end
    end

    context 'with an invalid command' do
      let(:command) { 'rstart' }

      it 'shows a helpful error message' do
        argv = [command]

        expect_output(:warn, message: "rstart is not a KDK command, did you mean - 'kdk restart' or 'kdk start'?")
        expect_output(:puts)
        expect_output(:info, message: "See 'kdk help' for more detail.")

        expect(described_class.run(argv)).to be_falsey
      end
    end
  end

  describe '.validate_config!' do
    let(:raw_yaml) { nil }

    before do
      remove_memoized_instance_variable(KDK, :@config)
      stub_raw_kdk_yaml(raw_yaml)
    end

    after do
      remove_memoized_instance_variable(KDK, :@config)
    end

    context 'with valid YAML', :hide_output do
      let(:raw_yaml) { "---\nkdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.validate_config!).to be_nil
      end
    end

    shared_examples 'invalid YAML' do |error_message|
      it 'prints an error' do
        expect(KDK::Output).to receive(:error).with("Your KDK configuration is invalid.\n\n", StandardError)
        expect(KDK::Output).to receive(:puts).with(error_message, stderr: true)

        expect { described_class.validate_config! }.to raise_error(SystemExit).and output("\n").to_stderr
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug" }

      # Ruby 3.3 warns with 'an instance of String'
      # Ruby 3.4 warns with 'fetch'
      it_behaves_like 'invalid YAML', /undefined method (`|')fetch' for ("debug":String|an instance of String)/
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug: fals" }

      it_behaves_like 'invalid YAML', "Value 'fals' for setting 'kdk.debug' is not a valid bool."
    end
  end

  describe '.check_workspace_setup_complete', :hide_output do
    let(:argv) { ['help'] }
    let(:in_workspace) { false }
    let(:setup_finished) { false }
    let(:cache_setup_complete) { KDK.config.__cache_dir.join('.kdk_setup_complete') }
    let(:help_text) { "Help! I need somebody! Help!\n" }

    subject(:run) do
      expect { described_class.run(argv) }.to raise_error(SystemExit)
    end

    before do
      stub_env('KS_WORKSPACE_DOMAIN_TEMPLATE', in_workspace ? '1' : nil)

      allow(KDK::Logo).to receive(:print)
      allow(KDK::Command::Help).to receive(:help).and_return([KDK::Command::BaseCommand::HelpItem.new(subcommand: '', description: help_text)])
      allow(FileTest).to receive(:exist?).with(cache_setup_complete.to_s).and_return(setup_finished)
    end

    it 'does not warn anything' do
      expect(KDK::Output).to receive(:puts).with(/#{help_text}/)
      expect(KDK::Output).not_to receive(:warn).with('KDK setup in progress...')

      run
    end

    context 'when in Workspace' do
      let(:in_workspace) { true }

      it 'warns about setup in progress' do
        expect(KDK::Output).to receive(:puts).with(/#{help_text}/)
        expect(KDK::Output).to receive(:warn).with('KDK setup in progress...')
        expect(KDK::Output).to receive(:puts).with('Run `tail -f /projects/workspace-logs/poststart-stdout.log` to watch the progress.')

        run
      end

      context 'when command errors' do
        before do
          help = instance_double(KDK::Command::Help)

          allow(help).to receive(:run).and_raise(KDK::UserInteractionRequired, '')
          allow(KDK::Command::Help).to receive(:new).and_return(help)
        end

        it 'still warnings about setup in progress' do
          expect(KDK::Output).not_to receive(:puts).with(help_text)
          expect(KDK::Output).to receive(:warn).with('KDK setup in progress...')

          run
        end
      end

      context 'when setup finished' do
        let(:setup_finished) { true }

        it 'does not warn anything' do
          expect(KDK::Output).to receive(:puts).with(/#{help_text}/)
          expect(KDK::Output).not_to receive(:warn).with('KDK setup in progress...')

          run
        end
      end

      context 'when running config command' do
        let(:argv) { ['config'] }

        it 'does not warn about setup in progress' do
          expect(KDK::Output).not_to receive(:warn).with('KDK setup in progress...')
          expect(KDK::Output).not_to receive(:puts).with('Run `tail -f /projects/workspace-logs/poststart-stdout.log` to watch the progress.')

          run
        end
      end
    end
  end

  private

  def expect_output(level, message: nil)
    expect(KDK::Output).to receive(level).with(message || no_args)
  end
end
