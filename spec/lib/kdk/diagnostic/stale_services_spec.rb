# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::StaleServices do
  include ShelloutHelper

  let(:stale_processes) do
    <<~STALE_PROCESSES
      95010 1 Ss   runsv rails-web
      95011 1 Ss   runsv rails-actioncable
    STALE_PROCESSES
  end

  let(:defunct_process) do
    <<~DEFUNCT_PROCESS
      42381 1 Z    runsv vite
    DEFUNCT_PROCESS
  end

  let(:service_mock) { Struct.new(:name) }
  let(:service_names) { %w[rails-web] }
  let(:services) { service_names.map { |name| service_mock.new(name) } }
  let(:legacy_service_names) { %w[rails-actioncable] }
  let(:legacy_services) { legacy_service_names.map { |name| service_mock.new(name) } }

  before do
    allow(KDK::Services).to receive_messages(all: services, legacy: legacy_services)
  end

  describe '#success?' do
    before do
      stub_ps(output, exit_code: exit_code)
    end

    context 'but ps fails' do
      let(:exit_code) { 2 }
      let(:output) { '' }

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end

    context 'and ps succeeds' do
      context 'and there are no stale processes' do
        let(:exit_code) { 1 }
        let(:output) { '' }

        it 'returns true' do
          expect(subject).to be_success
        end
      end

      context 'but there are stale processes' do
        let(:exit_code) { 0 }
        let(:output) { stale_processes }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context 'but there are both stale and defunct processes' do
        let(:exit_code) { 0 }
        let(:output) { "#{stale_processes}#{defunct_process}" }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end
    end
  end

  describe '#detail' do
    before do
      stub_ps(output, exit_code: exit_code)
    end

    context 'but ps fails' do
      let(:output) { nil }
      let(:exit_code) { 2 }

      it "return 'Unable to run 'ps' command." do
        expect(subject.detail).to eq("Unable to run '#{subject.send(:command)}'.")
      end
    end

    context 'and ps succeeds' do
      context 'and there are no stale processes' do
        let(:exit_code) { 1 }
        let(:output) { '' }

        it 'returns nil' do
          expect(subject.detail).to be_nil
        end
      end

      context 'but there are stale processes' do
        let(:exit_code) { 0 }
        let(:output) { stale_processes }

        it 'returns help message' do
          expect(subject.detail).to eq("The following KDK services appear to be stale:\n\nrails-web\nrails-actioncable\n\nYou can try killing them by running 'kdk kill' or:\n\n kill 95010 95011")
        end
      end

      context 'but there is a defunct process' do
        let(:exit_code) { 0 }
        let(:output) { defunct_process }

        it 'returns defunct process message' do
          expected_message = <<~MESSAGE.chomp
            The following KDK services are defunct (zombie processes):

            42381 - vite

            These services are not running but still show up in the process list.
            Try running 'kdk restart' to remove them.
          MESSAGE

          expect(subject.detail).to eq(expected_message)
        end
      end
    end
  end

  def stub_ps(result, exit_code: true)
    shellout = kdk_shellout_double(read_stdout: result, exit_code: exit_code)
    full_command = %(ps -eo pid,ppid,state,command | awk '$2 == 1' | grep -E "runsv (#{(service_names + legacy_service_names).join('|')})" | grep -v grep)
    allow_kdk_shellout_command(full_command).and_return(shellout)
    allow(shellout).to receive(:execute).and_return(shellout)
  end
end
