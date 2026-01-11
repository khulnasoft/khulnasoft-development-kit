# frozen_string_literal: true

RSpec.describe KDK::Complib::SmokeTestHelper, :hide_output do
  include described_class

  describe '#retry_until_true' do
    before do
      allow(Kernel).to receive(:sleep)
    end

    context 'when block returns true immediately' do
      it 'succeeds without retrying' do
        n = 0
        retry_until_true do
          n += 1
          true
        end
        expect(n).to eq(1)
      end
    end

    context 'when block eventually returns true' do
      it 'retries until success' do
        call_count = 0
        expect(Kernel).to receive(:sleep).with(1).twice
        retry_until_true(times: 5, delay: 1) do
          call_count += 1
          call_count >= 3
        end

        expect(call_count).to eq(3)
      end
    end

    context 'when block never returns true' do
      it 'raises an error after max attempts' do
        expect do
          retry_until_true(times: 3) { false }
        end.to raise_error('Failed after 3 attempts.')
      end

      it 'uses default times of 15' do
        call_count = 0
        expect do
          retry_until_true do
            call_count += 1
            false
          end
        end.to raise_error('Failed after 15 attempts.')

        expect(call_count).to eq(15)
      end
    end

    context 'when block raises an error' do
      it 'continues retrying' do
        call_count = 0
        retry_until_true(times: 5) do
          call_count += 1
          raise StandardError if call_count < 3

          true
        end

        expect(call_count).to eq(3)
      end

      it 'raises error after max attempts when block always raises' do
        expect do
          retry_until_true(times: 2) { raise StandardError }
        end.to raise_error('Failed after 2 attempts.')
      end
    end

    context 'with custom parameters' do
      it 'respects the times parameter' do
        call_count = 0
        expect do
          retry_until_true(times: 2) do
            call_count += 1
            false
          end
        end.to raise_error('Failed after 2 attempts.')

        expect(call_count).to eq(2)
      end

      it 'uses delay of 5 between retries' do
        expect(Kernel).to receive(:sleep).with(5).exactly(10).times
        expect do
          retry_until_true(times: 10) { false }
        end.to raise_error(/Failed after 10 attempts./)
      end
    end
  end
end
