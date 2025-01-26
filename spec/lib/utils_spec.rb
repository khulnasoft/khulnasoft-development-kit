# frozen_string_literal: true

RSpec.describe Utils do
  let(:tmp_path) { Dir.mktmpdir('kdk-path') }

  before do
    unstub_find_executable
    stub_env('PATH', tmp_path)
  end

  describe '.find_executable' do
    it 'returns the full path of the executable' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable('dummy')).to eq(executable)
    end

    it 'returns nil when executable cant be found' do
      expect(described_class.find_executable('non-existent')).to be_nil
    end

    it 'also finds by absolute path' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable(executable)).to eq(executable)
    end
  end

  describe '.executable_exist?' do
    it 'returns true if an executable exists in the PATH' do
      create_dummy_executable('dummy')

      expect(described_class.executable_exist?('dummy')).to be_truthy
    end

    it 'returns false when no exectuable can be found' do
      expect(described_class.executable_exist?('non-existent')).to be_falsey
    end
  end
end
