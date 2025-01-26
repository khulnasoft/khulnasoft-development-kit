# frozen_string_literal: true

RSpec.describe 'rake khulnasoft:truncate_logs', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/khulnasoft')
  end

  let(:log_dir) { Pathname.new(Dir.mktmpdir('khulnasoft-log-dir')) }
  let(:log_file) { log_dir.join('test.log') }

  before do
    allow(KDK.config).to receive_message_chain(:khulnasoft, :log_dir).and_return(log_dir)
    log_file.write('test data')
  end

  context 'when the user confirms' do
    before do
      stub_prompt('y')
    end

    it 'truncates all files in the log directory' do
      expect(log_file).to exist

      task.execute

      expect(log_file).to be_empty
    end
  end

  context 'when the user declines' do
    before do
      stub_prompt('n')
    end

    it 'does not truncate any files' do
      expect(log_file).to exist

      task.execute

      expect(log_file.read).to eq('test data')
    end
  end
end
