# frozen_string_literal: true

RSpec.describe KDK::Command::Rake do
  let(:args) { [] }

  it 'calls Rake.application.run with args' do
    expect(Rake.application).to receive(:run).with(args)
    subject.run(args)
  end

  context 'with some arguments' do
    let(:args) { %w[update:tool-versions] }

    it 'calls Rake.application.run with arguments' do
      expect(Rake.application).to receive(:run).with(args)
      subject.run(args)
    end
  end

  context 'when rake fails' do
    it 'propagates the error' do
      expect(Rake.application).to receive(:run).with(args).and_raise(Rake::TaskArgumentError)
      expect { subject.run(args) }.to raise_error(Rake::TaskArgumentError)
    end
  end
end
