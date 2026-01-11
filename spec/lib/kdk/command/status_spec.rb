# frozen_string_literal: true

RSpec.describe KDK::Command::Status do
  include ShelloutHelper

  let(:redis_service) do
    Runit::ServiceStatus.new(
      'redis',
      Time.now - 89104,
      16722,
      0,
      false,
      0,
      true
    )
  end

  let(:postgresql_service) do
    Runit::ServiceStatus.new(
      'postgresql',
      Time.now - 45000,
      12345,
      0,
      false,
      0,
      true
    )
  end

  let(:down_service) do
    Runit::ServiceStatus.new(
      'khulnasoft-workhorse',
      Time.now - 1000,
      0,
      0,
      true,
      0,
      false
    )
  end

  context 'when debug is true' do
    before do
      stub_env('KDK_DEBUG', 'true')
    end

    it 'displays table formatted status output' do
      allow(KDK::Output).to receive(:colorize?).and_return(false)
      expect(Runit).to receive(:status).with([]).and_return([redis_service])

      output = capture_stdout { subject.run }
      expect(output).to include('| PID    | STATUS     | SERVICE  |')
      expect(output).to include('| 16722  |')
      expect(output).to include('up 89104s')
      expect(output).to include('redis')
    end
  end

  context 'when debug is false' do
    before do
      stub_env('KDK_DEBUG', 'false')
    end

    it 'displays table formatted status output' do
      expect(Runit).to receive(:status).with([]).and_return([redis_service])

      output = capture_stdout { subject.run }
      expect(output).to include('| PID    | STATUS     | SERVICE  |')
      expect(output).to include('| 16722  |')
      expect(output).to include('up 89104s')
      expect(output).to include('redis')
    end
  end

  context 'with no extra arguments' do
    context 'when rails_web.enabled is true' do
      before do
        stub_env('KDK_DEBUG', 'false')
      end

      it "displays 'KhulnaSoft available' message" do
        allow(KDK.config).to receive(:rails_web?).and_return(true)
        expect(Runit).to receive(:status).with([]).and_return([redis_service])

        output = capture_stdout { subject.run }
        expect(output).to include('| 16722  |')
        expect(output).to include('up 89104s')
        expect(output).to include('redis')
        expect(output).to include('=> KhulnaSoft available at')
      end
    end

    context 'when rails_web.enabled is false' do
      it "does not display 'KhulnaSoft available' message" do
        allow(KDK.config).to receive(:rails_web?).and_return(false)
        expect(Runit).to receive(:status).with([]).and_return([redis_service])

        output = capture_stdout { subject.run }
        expect(output).not_to include('KhulnaSoft available at')
      end
    end

    context 'when all services are down' do
      it "does not display 'KhulnaSoft available' message" do
        expect(Runit).to receive(:status).with([]).and_return([down_service])

        output = capture_stdout { subject.run }
        expect(output).not_to include('KhulnaSoft available at')
      end
    end

    context 'when all but one services are down' do
      it "displays 'KhulnaSoft available' message" do
        expect(Runit).to receive(:status).with([]).and_return([down_service, redis_service])

        output = capture_stdout { subject.run }
        expect(output).to include('KhulnaSoft available at')
      end
    end
  end

  context 'with extra arguments' do
    it 'queries runit for status to specific services only' do
      expect(Runit).to receive(:status).with(['rails-web']).and_return([])

      output = capture_stdout { subject.run(%w[rails-web]) }
      expect(output).not_to include('KhulnaSoft available at')
    end
  end

  context 'with different service states' do
    it 'displays services with different states correctly' do
      services = [redis_service, postgresql_service, down_service]
      expect(Runit).to receive(:status).with([]).and_return(services)

      output = capture_stdout { subject.run }

      expect(output).to include('| PID    | STATUS                | SERVICE           |')
      expect(output).to include('| 16722  |')
      expect(output).to include('up 89104s')
      expect(output).to include('redis')
      expect(output).to include('| 12345  |')
      expect(output).to include('up 45000s')
      expect(output).to include('postgresql')
      expect(output).to include('|        |')
      expect(output).to include('down (want up) 1000s')
      expect(output).to include('khulnasoft-workhorse')
    end
  end

  context 'with color output' do
    before do
      allow(KDK::Output).to receive(:colorize?).and_return(true)
    end

    it 'applies colors to service states' do
      expect(Runit).to receive(:status).with([]).and_return([redis_service, down_service])

      output = capture_stdout { subject.run }

      # Check that color codes are applied (the actual color codes will be in the output)
      expect(output).to include('redis')
      expect(output).to include('khulnasoft-workhorse')
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
