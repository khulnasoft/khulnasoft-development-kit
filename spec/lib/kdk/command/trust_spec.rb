# frozen_string_literal: true

RSpec.describe KDK::Command::Trust do
  it 'warns with a deprecation message' do
    stub_no_color_env('true')

    expect { subject.run }.to output("'kdk trust' is deprecated and no longer required.\n").to_stdout
  end
end
