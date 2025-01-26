# frozen_string_literal: true

RSpec.describe KDK::Command::Run do
  it 'aborts and returns a deprecation message' do
    expect { subject.run }.to raise_error(SystemExit).and output(/is no longer available/).to_stderr
  end
end
