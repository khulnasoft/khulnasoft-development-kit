# frozen_string_literal: true

RSpec.describe KDK::Command::Help do
  let(:args) { [] }
  let(:out) { KDK::Output }
  let(:help_command) { described_class.new(out: out) }

  describe '.validate_config?' do
    it 'returns false to allow invalid kdk.yml' do
      expect(described_class.validate_config?).to be(false)
    end
  end

  describe '#run' do
    def help(subcommand = nil, description = nil)
      unless description
        description = subcommand
        subcommand = nil
      end

      KDK::Command::BaseCommand::HelpItem.new(subcommand: subcommand, description: description)
    end

    let(:mock_commands) do
      {
        'start' => -> { class_double(KDK::Command::BaseCommand, name: 'Start', help: [help('Start all services')]) },
        'stop' => -> { class_double(KDK::Command::BaseCommand, name: 'Stop', help: [help('Stop all services')]) },
        'status' => lambda {
          class_double(KDK::Command::BaseCommand, name: 'Status', help: [
            help('Show service status'),
            help('my_service', 'Show service status for given service')
          ])
        },
        # internal command without help
        'woof' => -> { class_double(KDK::Command::BaseCommand, name: 'Woof', help: []) }
      }
    end

    before do
      allow(out).to receive(:puts)
      stub_env('NO_COLOR', '1')
      stub_const('KDK::VERSION', 'KhulnaSoft Development Kit 1.0.0')
      stub_const('KDK::Command::COMMANDS', mock_commands)
    end

    it 'prints the logo' do
      expect(KDK::Logo).to receive(:print)
      help_command.run(args)
    end

    it 'displays help content with version and returns true' do
      expected_help = <<~HELP
        KhulnaSoft Development Kit 1.0.0

        Usage:
          kdk <command> [<args>]

        Commands:
          start             # Start all services
          status            # Show service status
          status my_service # Show service status for given service
          stop              # Stop all services

        # Development admin account: root / 5iveL!fe

        For more information about KhulnaSoft development see
        https://docs.khulnasoft.com/ee/development/index.html.
      HELP

      expect(KDK::Logo).to receive(:print)
      expect(out).to receive(:puts).with(expected_help)
      expect(help_command.run(args)).to be(true)
    end
  end
end
