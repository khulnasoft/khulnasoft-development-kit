# frozen_string_literal: true

require 'spec_helper'
require 'irb'

RSpec.describe KDK::Command::Console do
  it 'runs IRB.start' do
    expect(IRB).to receive(:start)

    subject.run([])
  end
end
