# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::HttpRouter do
  let(:not_ok_log_size) { described_class::HTTP_ROUTER_LOG_SIZE_NOT_OK_MB + 1 }
  let(:ok_log_size) { described_class::HTTP_ROUTER_LOG_SIZE_NOT_OK_MB - 1 }

  describe '#success?' do
    context 'when HTTP router is disabled' do
      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain(:khulnasoft_http_router, :enabled?).and_return(false)
      end

      it 'returns true' do
        expect(subject.success?).to be_truthy
      end
    end

    context 'when HTTP router is enabled' do
      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain(:khulnasoft_http_router, :enabled?).and_return(true)
      end

      context 'when log file does not exist' do
        before do
          stub_http_router_log_file(exist: false)
        end

        it 'returns true' do
          expect(subject.success?).to be_truthy
        end
      end

      context 'when log file exists' do
        before do
          stub_http_router_log_file(exist: true)
        end

        context 'when log file size is not OK' do
          before do
            stub_http_router_log_file_size(not_ok_log_size)
          end

          it 'returns false' do
            expect(subject.success?).to be_falsey
          end
        end

        context 'when log file size is OK' do
          before do
            stub_http_router_log_file_size(ok_log_size)
          end

          it 'returns true' do
            expect(subject.success?).to be_truthy
          end
        end
      end
    end
  end

  describe '#detail' do
    context 'when HTTP router is disabled' do
      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain(:khulnasoft_http_router, :enabled?).and_return(false)
      end

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end

    context 'when HTTP router is enabled and log file exists' do
      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain(:khulnasoft_http_router, :enabled?).and_return(true)
        stub_http_router_log_file(exist: true)
      end

      context 'when log file size is not OK' do
        before do
          stub_http_router_log_file_size(not_ok_log_size)
        end

        it 'returns detail content with size and truncation command' do
          expected_message = /Your HTTP Router log file is #{not_ok_log_size}MB.*You can truncate the log file if you wish.*rake khulnasoft:truncate_http_router_logs/m

          expect(subject.detail).to match(expected_message)
        end
      end

      context 'when log file size is OK' do
        before do
          stub_http_router_log_file_size(ok_log_size)
        end

        it 'returns nil' do
          expect(subject.detail).to be_nil
        end
      end
    end
  end

  private

  def stub_http_router_log_file(exist: true)
    log_file_path = '/home/git/kdk/tmp/log/khulnasoft-http-router.log'
    double = instance_double(Pathname, exist?: exist, to_s: log_file_path)
    allow_any_instance_of(KDK::Config).to receive(:kdk_root).and_return(instance_double(Pathname))
    allow_any_instance_of(KDK::Config).to receive_message_chain(:kdk_root, :join).and_return(double)
    double
  end

  def stub_http_router_log_file_size(size_in_mb)
    size_in_bytes = size_in_mb * described_class::BYTES_TO_MEGABYTES
    log_file_double = stub_http_router_log_file(exist: true)
    allow(log_file_double).to receive(:size).and_return(size_in_bytes)
  end
end
