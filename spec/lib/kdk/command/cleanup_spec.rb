# frozen_string_literal: true

RSpec.describe KDK::Command::Cleanup do
  subject { described_class.new }

  describe '#run' do
    context 'when not confirmed' do
      it 'returns true' do
        stub_prompt('n')

        expect_warn_and_puts
        expect(subject).not_to receive(:execute)

        expect(subject.run).to be_truthy
      end
    end

    context 'when confirmed' do
      context 'but an unhandled error occurs' do
        it 'calls execute but returns false' do
          exception = StandardError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts
          expect(KDK::Output).to receive(:error).with(exception)

          expect(subject.run).to be_falsey
        end
      end

      context 'but a RuntimeError error occurs' do
        it 'calls execute, outputs the RuntimeError and returns false' do
          exception = RuntimeError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          rake_http_router_truncate_double = stub_rake_http_router_truncate
          allow(rake_http_router_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts

          expect(KDK::Output).to receive(:error).twice.with('a failure occured', exception)

          expect(subject.run).to be(false)
        end
      end

      context 'and without any errors' do
        context 'via direct response' do
          it 'calls execute' do
            stub_prompt('y')

            expect_warn_and_puts
            expect_rake_and_http_router_truncate

            expect(subject.run).to be_truthy
          end
        end

        context 'by setting KDK_CLEANUP_CONFIRM to true' do
          it 'calls execute' do
            stub_env('KDK_CLEANUP_CONFIRM', 'true')

            expect_warn_and_puts
            expect_rake_and_http_router_truncate

            expect(subject.run).to be_truthy
          end
        end
      end
    end

    def expect_warn_and_puts
      expect(KDK::Output).to receive(:warn).with('About to perform the following actions:').ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
      expect_truncate_puts

      return if ENV.fetch('KDK_CLEANUP_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

      expect(KDK::Output).to receive(:puts).with(stderr: true).at_least(:once).ordered
    end

    def expect_truncate_puts
      expect(KDK::Output).to receive(:puts).with('- Truncate khulnasoft/log/* files', stderr: true).ordered
      expect(KDK::Output).to receive(:puts).with("- Truncate #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file", stderr: true).ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
    end

    def expect_rake_and_http_router_truncate
      expect_rake_truncate
      expect_rake_http_router_truncate
    end

    def stub_rake_truncate
      stub_rake_task('khulnasoft:truncate_logs', 'khulnasoft.rake')
    end

    def stub_rake_http_router_truncate
      stub_rake_task('khulnasoft:truncate_http_router_logs', 'khulnasoft.rake')
    end

    def expect_rake_truncate
      expect_rake_task('khulnasoft:truncate_logs', 'khulnasoft.rake', args: 'false')
    end

    def expect_rake_http_router_truncate
      expect_rake_task('khulnasoft:truncate_http_router_logs', 'khulnasoft.rake', args: 'false')
    end

    def stub_rake_task(task_name, rake_file)
      allow(Kernel).to receive(:load).with(KDK.root.join('lib', 'tasks', rake_file)).and_return(true)
      rake_task_double = double("#{task_name} rake task") # rubocop:todo RSpec/VerifiedDoubles
      allow(Rake::Task).to receive(:[]).with(task_name).and_return(rake_task_double)
      rake_task_double
    end

    def expect_rake_task(task_name, rake_file, args: nil)
      rake_task_double = stub_rake_task(task_name, rake_file)
      expect(rake_task_double).to receive(:invoke).with(args).and_return(true)
    end
  end
end
