# frozen_string_literal: true

RSpec.describe KDK do
  describe '.config' do
    it 'returns memoized config' do
      stub_kdk_yaml({})

      config = described_class.config
      expect(described_class.config).to eql(config)
    end
  end

  describe '.main' do
    it 'calls setup_rake and delegates ARGV to Command.run' do
      expect(described_class).to receive(:setup_rake)

      args = ['args']
      stub_const('ARGV', args)

      expect(KDK::Command).to receive(:run).with(args)

      described_class.main
    end
  end

  describe '.setup_rake' do
    it 'initializes rake' do
      expect(Rake.application).to receive(:init)
        .with('rake', %W[--rakefile #{described_class.root}/Rakefile])

      expect(Rake.application).to receive(:load_rakefile)

      described_class.setup_rake
    end
  end
end
