# frozen_string_literal: true

RSpec.describe KDK::Command::Env do
  let(:env) { subject.send(:env) }

  describe '#help' do
    it 'returns a detailed help message' do
      expect(subject.help).to include('Usage: kdk env')
      expect(subject.help).to include('-h, --help')
      expect(subject.help).to include('gitaly')
    end
  end

  describe '#run' do
    context 'when --help is passed' do
      it 'prints help and returns true' do
        expect(subject).to receive(:print_help).with(['--help']).and_return(true)
        expect(subject.run(['--help'])).to be(true)
      end
    end

    context 'when -h is passed' do
      it 'prints help and returns true' do
        expect(subject).to receive(:print_help).with(['-h']).and_return(true)
        expect(subject.run(['-h'])).to be(true)
      end
    end
  end

  context 'when running from gitaly folder' do
    before do
      allow(KDK).to receive(:pwd).and_return(KDK.root.join('gitaly'))
    end

    context 'with no extra arguments' do
      it 'outputs gitaly specific ENV context' do
        expect { subject.run }.to output(/export PGHOST=.+\nexport PGPORT=.+/).to_stdout
      end
    end

    context 'with extra arguments' do
      it 'executes passed arguments withing gitaly specific ENV context' do
        command = 'pwd'

        expect(subject).to receive(:exec).with(env, command, chdir: KDK.pwd)

        subject.run([command])
      end
    end
  end

  context 'when running from main folder or from an unsupported service folder' do
    it 'does not output anything' do
      expect { subject.run }.not_to output.to_stdout
    end
  end
end
