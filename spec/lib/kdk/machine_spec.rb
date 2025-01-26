# frozen_string_literal: true

RSpec.describe KDK::Machine do
  subject { described_class }

  describe '.linux?' do
    context 'on a macOS system' do
      it 'returns false' do
        stub_macos

        expect(subject.linux?).to be(false)
      end
    end

    context 'on a Linux system' do
      it 'returns true' do
        stub_linux

        expect(subject.linux?).to be(true)
      end
    end

    context 'on a Linux system (WSL)' do
      it 'returns true' do
        stub_wsl

        expect(subject.linux?).to be(true)
      end
    end
  end

  describe '.macos?' do
    context 'on a Linux system' do
      it 'returns false' do
        stub_linux

        expect(subject.macos?).to be(false)
      end
    end

    context 'on a macOS system' do
      it 'returns true' do
        stub_macos

        expect(subject.macos?).to be(true)
      end
    end
  end

  describe '.wsl?' do
    it 'returns true on WSL' do
      stub_wsl

      expect(subject.wsl?).to be(true)
    end

    it 'returns false on native Linux' do
      stub_linux

      expect(subject.wsl?).to be(false)
    end

    it 'returns false on native MacOS' do
      stub_macos

      expect(subject.wsl?).to be(false)
    end

    it 'returns false on native Windows' do
      stub_windows

      expect(subject.wsl?).to be(false)
    end
  end

  describe '.platform' do
    context 'when macOS' do
      it 'returns darwin' do
        stub_macos

        expect(subject.platform).to eq('darwin')
      end
    end

    context 'when Linux' do
      it 'returns linux' do
        stub_linux

        expect(subject.platform).to eq('linux')
      end
    end

    context 'when Linux (WSL)' do
      it 'returns linux' do
        stub_wsl

        expect(subject.platform).to eq('linux')
      end
    end

    context 'when neither macOS of Linux' do
      it 'returns unknown' do
        stub_windows

        expect(subject.platform).to eq('unknown')
      end
    end
  end

  describe '.x86_64?' do
    context 'when CPU is reporting an x86_64 architecture' do
      it 'returns true' do
        stub_x86_64

        expect(subject.x86_64?).to be_truthy
      end
    end

    context 'when CPU is reporting an ARM based architecture' do
      it 'returns false' do
        stub_arm64

        expect(subject.x86_64?).to be_falsey
      end
    end
  end

  describe '.arm64?' do
    context 'when CPU is reporting arm64 architecture' do
      it 'returns true' do
        stub_arm64

        expect(subject.arm64?).to be_truthy
      end
    end

    context 'when CPU is reporting aarch64 architecture' do
      it 'returns true' do
        stub_aarch64

        expect(subject.arm64?).to be_truthy
      end
    end

    context 'when CPU is reporting x86_64 architecture' do
      it 'returns false' do
        stub_x86_64

        expect(subject.arm64?).to be_falsey
      end
    end
  end

  describe '.architecture' do
    context 'when in a x86_64' do
      it 'returns x86_64' do
        stub_x86_64

        expect(subject.architecture).to eq('amd64')
      end
    end

    context 'when in an ARMv8 / Apple Silicon' do
      it 'returns arch64' do
        stub_arm64

        expect(subject.architecture).to eq('arm64')
      end
    end
  end

  describe '.package_platform' do
    it 'returns platform-arch' do
      expect(described_class.package_platform).to eq("#{described_class.platform}-#{described_class.architecture}")
    end

    context 'BUILD_ARCH env variable is set' do
      it 'returns platform-BUILD_ARCH' do
        allow(ENV).to receive(:[]).with('BUILD_ARCH').and_return('testarch')
        expect(described_class.package_platform).to eq("#{described_class.platform}-testarch")
      end
    end
  end

  def stub_macos
    allow(Etc).to receive(:uname).and_return({ release: "22.6.0" })
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('darwin21')
  end

  def stub_linux
    allow(Etc).to receive(:uname).and_return({ release: "6.4.10-200.fc38.x86_64" }) # fedora linux
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('linux')
  end

  def stub_windows
    allow(Etc).to receive(:uname).and_return({ release: '10.0.22621' }) # windows 11
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('mswin32')
  end

  def stub_wsl
    allow(Etc).to receive(:uname).and_return({ release: "5.15.90.1-microsoft-standard-WSL2" })
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('linux')
  end

  def stub_x86_64
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('x86_64')
  end

  def stub_arm64
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('arm64')
  end

  def stub_aarch64
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with('target_cpu').and_return('aarch64')
  end
end
