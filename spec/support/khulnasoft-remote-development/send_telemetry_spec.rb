# frozen_string_literal: true

require_relative '../../../support/khulnasoft-remote-development/send_telemetry'

RSpec.describe SendTelemetry do
  include ShelloutHelper

  let(:success) { true }
  let(:duration) { 10 }
  let(:telemetry_enabled) { true }
  let(:poststart_log_file) { '/projects/workspace-logs/poststart-stdout.log' }

  let(:send_telemetry) { described_class.new }

  before do
    stub_const('KDK::Config::FILE', temp_path.join('kdk.yml'))
    stub_persisted_kdk_yaml({ 'telemetry' => { 'enabled' => telemetry_enabled } })
    stub_env('GL_WORKSPACE_DOMAIN_TEMPLATE', 'workspace.example.com')

    allow(send_telemetry).to receive(:system).and_return(true)
    allow(FileUtils).to receive(:touch)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(poststart_log_file).and_return(false)
  end

  describe '#run', :hide_output do
    context 'when setup flag file does not exist after 15 minutes' do
      before do
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(false)
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE).and_return(false)
        allow(send_telemetry).to receive(:wait_for_setup_flag_file).and_return(false)
        allow(send_telemetry).to receive(:sleep)
      end

      it 'sends telemetry with failure status' do
        send_telemetry.run

        expect(send_telemetry).to have_received(:system).with(
          'kdk',
          'send-telemetry',
          'workspace_setup_duration',
          '',
          '--extra=success:false'
        )
      end

      it 'creates the telemetry flag file' do
        send_telemetry.run

        expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
      end
    end

    context 'when setup flag file exists' do
      before do
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(true)
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE).and_return(false)
      end

      context 'when setup flag file is empty' do
        before do
          allow(File).to receive(:empty?).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(true)
        end

        it 'sends telemetry with failure and nil duration' do
          send_telemetry.run

          expect(send_telemetry).to have_received(:system).with(
            'kdk',
            'send-telemetry',
            'workspace_setup_duration',
            '',
            '--extra=success:false'
          )
        end
      end

      context 'when setup flag file contains duration and successful status code' do
        before do
          allow(File).to receive(:read).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return("0 #{duration}")
        end

        context 'when telemetry is enabled' do
          context 'with function durations in log file' do
            before do
              allow(File).to receive(:exist?).with(poststart_log_file).and_return(true)
              allow(File).to receive(:read).with(poststart_log_file).and_return(<<~LOG)
                Some other log content
                Execution times for each function:
                migrate_db: 185 seconds
                update_kdk: 479 seconds
                restart_kdk: 9 seconds
              LOG
            end

            it 'sends telemetry with function durations' do
              send_telemetry.run

              expect(send_telemetry).to have_received(:system).with(
                'kdk',
                'send-telemetry',
                'workspace_setup_duration',
                duration.to_s,
                '--extra=success:true',
                '--extra=migrate_db:185',
                '--extra=update_kdk:479',
                '--extra=restart_kdk:9'
              )
            end
          end

          it 'creates the telemetry flag file' do
            send_telemetry.run

            expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
          end
        end

        context 'when telemetry is disabled' do
          let(:telemetry_enabled) { false }

          it 'does not send telemetry' do
            send_telemetry.run

            expect(send_telemetry).not_to have_received(:system)
          end

          it 'still creates the telemetry flag file' do
            send_telemetry.run

            expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
          end
        end
      end

      context 'when setup flag file contains duration and error status code' do
        before do
          allow(File).to receive(:read).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return("1 #{duration}")
        end

        context 'when telemetry is enabled' do
          context 'with function durations in log file' do
            before do
              allow(File).to receive(:exist?).with(poststart_log_file).and_return(true)
              allow(File).to receive(:read).with(poststart_log_file).and_return(<<~LOG)
                Some other log content
                Execution times for each function:
                migrate_db: 185 seconds
                update_kdk: 479 seconds
                restart_kdk: 9 seconds
              LOG
            end

            it 'sends telemetry with function durations' do
              send_telemetry.run

              expect(send_telemetry).to have_received(:system).with(
                'kdk',
                'send-telemetry',
                'workspace_setup_duration',
                duration.to_s,
                '--extra=success:false',
                '--extra=migrate_db:185',
                '--extra=update_kdk:479',
                '--extra=restart_kdk:9'
              )
            end
          end

          it 'creates the telemetry flag file' do
            send_telemetry.run

            expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
          end
        end

        context 'when telemetry is disabled' do
          let(:telemetry_enabled) { false }

          it 'does not send telemetry' do
            send_telemetry.run

            expect(send_telemetry).not_to have_received(:system)
          end

          it 'still creates the telemetry flag file' do
            send_telemetry.run

            expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
          end
        end
      end
    end

    context 'when telemetry flag file exists' do
      before do
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(true)
        allow(File).to receive(:exist?).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE).and_return(true)
        allow(File).to receive(:read).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return("0 #{duration}")
      end

      context 'when telemetry has already been sent' do
        let(:setup_mtime) { Time.now - 3600 } # 1 hour ago
        let(:telemetry_mtime) { Time.now - 1800 } # 30 minutes ago

        before do
          allow(File).to receive(:mtime).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(setup_mtime)
          allow(File).to receive(:mtime).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE).and_return(telemetry_mtime)
        end

        it 'does not send telemetry again' do
          send_telemetry.run

          expect(send_telemetry).not_to have_received(:system)
          expect(FileUtils).not_to have_received(:touch)
        end
      end

      context 'when telemetry flag file is older than setup flag file' do
        let(:setup_mtime) { Time.now - 1800 } # 30 minutes ago
        let(:telemetry_mtime) { Time.now - 3600 } # 1 hour ago

        before do
          allow(File).to receive(:mtime).with(SendTelemetry::KDK_SETUP_FLAG_FILE).and_return(setup_mtime)
          allow(File).to receive(:mtime).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE).and_return(telemetry_mtime)
        end

        it 'sends telemetry and updates the flag file' do
          send_telemetry.run

          expect(send_telemetry).to have_received(:system).with(
            'kdk',
            'send-telemetry',
            'workspace_setup_duration',
            duration.to_s,
            '--extra=success:true'
          )
          expect(FileUtils).to have_received(:touch).with(SendTelemetry::KDK_TELEMETRY_FLAG_FILE)
        end
      end
    end
  end
end
