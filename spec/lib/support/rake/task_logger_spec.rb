# frozen_string_literal: true

RSpec.describe Support::Rake::TaskLogger do
  let(:task) { instance_double(Rake::Task, name: 'test task') }
  let(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
  let(:expected_path) { Pathname("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/test-task.log") }

  subject(:task_logger) { described_class.from_task(task) }

  before do
    allow(described_class).to receive(:start_time).and_return(now)
    allow(File).to receive(:symlink?).with("#{KDK.root}/log/kdk/rake-latest").and_return(false)
    allow(File).to receive(:readlink).with("#{KDK.root}/log/kdk/rake-latest").and_return(nil)
  end

  after do
    described_class.set_current!(nil)
  end

  describe '.current' do
    it 'returns nil by default' do
      expect(described_class.current).to be_nil
    end

    context 'after calling .set_current!' do
      before do
        described_class.set_current!(subject)
      end

      it 'returns the current logger' do
        expect(described_class.current).to be(subject)
      end
    end
  end

  describe '#initialize' do
    let(:expected_log_dir) { "#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279" }

    it 'creates the log dir' do
      expect(Dir.glob(subject.file_path.parent).first).to eq(expected_log_dir)

      subject
    end
  end

  describe '#file_path' do
    it 'returns the task- and date-specific file name' do
      expect(subject.file_path).to eq(expected_path)
    end

    context 'when the task name contains filesystem-relevant chracters' do
      let(:task) { instance_double(Rake::Task, name: 'khulnasoft/doc/api/graphql/reference/khulnasoft_schema.json') }
      let(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
      let(:expected_path) { Pathname("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/khulnasoft-doc-api-graphql-reference-khulnasoft_schema-json.log") }

      it 'escapes the task name' do
        expect(subject.file_path).to eq(expected_path)
      end
    end
  end

  describe '#file' do
    it 'opens a file based on the task name once' do
      f = file_double(size: 1)
      expect(File).to receive(:open).with(expected_path, 'w').once.and_return(f)

      expect(subject.file).to be(f)
    end
  end

  describe '.mark_as_failed!' do
    let(:task_failed_message) { "[#{now.strftime('%F %T.%6N')}] ERROR: --- Task #{task.name} failed ---" }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it 'marks the file as failed' do
      expect(subject.file).to receive(:puts).with(task_failed_message)
      subject.mark_as_failed!(task)
    end
  end

  describe '#cleanup!' do
    context 'when the log file was created' do
      let(:written_bytes) { 0 }
      let(:file) { file_double(size: written_bytes) }

      before do
        closed = false
        allow(File).to receive(:open).with(expected_path, 'w').and_return(file)
        allow(file).to receive(:closed?) { closed }
        allow(file).to receive(:close) do
          raise "tried closing closed file" if closed

          closed = true
        end
      end

      context 'when it was written to' do
        let(:written_bytes) { 42 }

        it 'only closes it' do
          expect(File).not_to receive(:delete)
          expect(file).to receive(:close)

          subject.file
          subject.cleanup!
        end
      end

      context 'when it is empty' do
        it 'closes and deletes it' do
          expect(File).to receive(:delete).with(expected_path)
          expect(file).to receive(:close)

          subject.file
          subject.cleanup!
        end

        context 'when delete: false is passed' do
          it 'only closes it' do
            expect(File).not_to receive(:delete).with(expected_path)
            expect(file).to receive(:close)

            subject.file
            subject.cleanup!(delete: false)
          end

          context 'when cleaning up multiple times' do
            it 'only runs once' do
              expect(File).not_to receive(:delete).with(expected_path)
              expect(file).to receive(:close).once

              subject.file
              subject.cleanup!(delete: false)
            end
          end
        end
      end
    end

    context 'when the log file was not created' do
      it 'does nothing' do
        expect(File).not_to receive(:delete)

        subject.cleanup!
      end
    end
  end

  describe '#recent_line' do
    subject { task_logger.recent_line }

    context 'without previous records' do
      it { is_expected.to be_nil }
    end

    context 'with records' do
      {
        nil => nil,
        '' => nil,
        '------' => nil,
        'single line' => 'single line',
        '5' => '5',
        "a\nb" => 'b',
        "--\na\n  \nb\n -- \n \n" => 'b',
        "a\nfile:23: DEPRECATION WARNING: beware!\n" => 'a'
      }.each do |input, expected|
        context "with input: #{input.inspect}" do
          before do
            task_logger.record_input(input)
          end

          it { is_expected.to eq(expected) }
        end
      end
    end
  end

  describe '#tail' do
    let(:content) { (0..30).map { |i| "An error occurred #{i}" }.join("\n") }

    before do
      allow(File).to receive(:read).with(expected_path).and_return(content)
    end

    it 'returns the last 25 lines' do
      expect(subject.tail).to eq <<~MESSAGE.strip
        An error occurred 6
        An error occurred 7
        An error occurred 8
        An error occurred 9
        An error occurred 10
        An error occurred 11
        An error occurred 12
        An error occurred 13
        An error occurred 14
        An error occurred 15
        An error occurred 16
        An error occurred 17
        An error occurred 18
        An error occurred 19
        An error occurred 20
        An error occurred 21
        An error occurred 22
        An error occurred 23
        An error occurred 24
        An error occurred 25
        An error occurred 26
        An error occurred 27
        An error occurred 28
        An error occurred 29
        An error occurred 30

        ... 6 lines omitted. See #{expected_path} for the full log.
      MESSAGE
    end

    context 'with broken encoding' do
      let(:content) { "\xc3\xa9\xc3\xa0\xc3" }

      it 'scrubs invalid chars' do
        expect(subject.tail).to eq 'éà?'
      end
    end

    context 'with a Ruby backtrace logged' do
      let(:content) do
        <<~MESSAGE
          (irb):3:in `<main>': test error (StandardError)
            from <internal:kernel>:187:in `loop'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/lib/ruby/gems/3.3.0/gems/irb-1.15.1/exe/irb:9:in `<top (required)>'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `load'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `<main>'
        MESSAGE
      end

      it 'hides gem paths' do
        expect(subject.tail).to eq <<~MESSAGE.strip
          (irb):3:in `<main>': test error (StandardError)
            from <internal:kernel>:187:in `loop'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `load'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `<main>'

          ... 1 lines omitted. See #{expected_path} for the full log.
        MESSAGE
      end

      context 'and "exclude_gems" set to false' do
        it 'returns the original backtrace' do
          expect(subject.tail(exclude_gems: false)).to eq(content.strip)
        end
      end
    end

    context 'with no error reported' do
      let(:content) { (0..30).map { |i| "Update of dependency #{i} successful" }.join("\n") }

      it 'returns nil' do
        expect(subject.tail(only_with_errors: true)).to be_nil
      end
    end

    context 'with smart_filter enabled' do
      let(:content) do
        <<~LOGS
          INFO: Starting task
          INFO: Processing item 1
          INFO: Processing item 2
          ERROR: Failed to process item 3
          INFO: Processing item 4
          WARNING: Slow query detected
          INFO: Processing item 5
          from /app/models/user.rb:42:in `validate'
          INFO: Processing item 6
          FATAL: Database connection lost
          INFO: Processing item 7
          [sentry] Event sent successfully
          INFO: Processing item 8
          mise all tools installed
          INFO: Processing item 9
          from /home/user/.rbenv/versions/3.2.0/lib/ruby/gems/3.2.0/gems/activerecord-7.0.0/lib/active_record.rb:123
          INFO: Processing item 10
          ActiveRecord::RecordInvalid raised
          PG::ConnectionBad: connection closed
          INFO: Processing item 11
          Task completed
        LOGS
      end

      it 'includes critical error lines when filtering' do
        result = subject.tail(smart_filter: true, max_lines: 10)

        expect(result).to include('ERROR: Failed to process item 3')
        expect(result).to include('FATAL: Database connection lost')
      end

      it 'respects max_lines limit' do
        result = subject.tail(smart_filter: true, max_lines: 5)
        result_lines = result.split("\n").reject { |l| l.include?('omitted') || l.strip.empty? }

        expect(result_lines.length).to be <= 5
      end

      it 'maintains original line order' do
        result = subject.tail(smart_filter: true, max_lines: 10)
        lines = result.split("\n").reject(&:empty?).reject { |l| l.include?('omitted') }

        error_idx = lines.index { |l| l.include?('ERROR: Failed') }
        fatal_idx = lines.index { |l| l.include?('FATAL: Database') }

        expect(error_idx).to be < fatal_idx if error_idx && fatal_idx
      end

      it 'falls back to returning all lines when content fits within max_lines' do
        short_content = "Line 1\nLine 2\nLine 3"
        allow(File).to receive(:read).with(expected_path).and_return(short_content)

        result = subject.tail(smart_filter: true, max_lines: 10)
        expect(result).to eq(short_content)
      end

      it 'shows omitted line count when lines are filtered' do
        result = subject.tail(smart_filter: true, max_lines: 5)

        expect(result).to match(/\.\.\. \d+ lines omitted\. See #{Regexp.escape(expected_path.to_s)} for the full log\./)
      end

      it 'does not show omitted line count when no lines are omitted' do
        short_content = "ERROR: Issue\nWARNING: Problem"
        allow(File).to receive(:read).with(expected_path).and_return(short_content)

        result = subject.tail(smart_filter: true, max_lines: 10)
        expect(result).not_to include('omitted')
      end
    end

    context 'with combined options' do
      let(:content) do
        <<~LOGS
          INFO: Starting
          ERROR: Something broke
          from /ruby/gems/3.2.0/lib/gem.rb:10
          WARNING: Be careful
          INFO: Continuing
          FATAL: Critical error
          INFO: Done
        LOGS
      end

      it 'applies all filters together' do
        result = subject.tail(smart_filter: true, exclude_gems: true, max_lines: 4)

        expect(result).not_to include('/ruby/gems/')
        expect(result).to match(/ERROR|FATAL|WARNING/)
      end
    end
  end

  describe '#smart_filter_lines' do
    it 'returns all lines when count is within max_lines' do
      lines = ['Line 1', 'Line 2', 'Line 3']
      allow(File).to receive(:read).with(expected_path).and_return(lines.join("\n"))

      result = subject.send(:smart_filter_lines, lines, 10)
      expect(result).to eq(lines)
    end

    it 'reduces lines to max_lines when necessary' do
      lines = (1..20).map { |i| "Line #{i}" }
      allow(File).to receive(:read).with(expected_path).and_return(lines.join("\n"))

      result = subject.send(:smart_filter_lines, lines, 5)
      expect(result.length).to eq(5)
    end

    it 'preserves original ordering of selected lines' do
      lines = %w[First Second Third Fourth Fifth]
      allow(File).to receive(:read).with(expected_path).and_return(lines.join("\n"))

      result = subject.send(:smart_filter_lines, lines, 3)

      selected_indices = result.map { |line| lines.index(line) }
      expect(selected_indices).to eq(selected_indices.sort)
    end
  end

  describe '#calculate_proximity_bonus' do
    it 'returns a numeric value' do
      line_scores = [0, 10, 0]

      bonus = subject.send(:calculate_proximity_bonus, line_scores, 0)
      expect(bonus).to be_a(Numeric)
    end

    it 'handles edge cases at array boundaries' do
      line_scores = [10, 0]

      expect { subject.send(:calculate_proximity_bonus, line_scores, 0) }.not_to raise_error
      expect { subject.send(:calculate_proximity_bonus, line_scores, 1) }.not_to raise_error
    end
  end

  describe '#has_errors?' do
    it 'returns true when error patterns are present' do
      lines_with_error = ['INFO: Starting', 'ERROR: Failed', 'INFO: Done']

      expect(subject.send(:has_errors?, lines_with_error)).to be true
    end

    it 'detects various error pattern formats' do
      test_cases = [
        'ERROR: Something went wrong',
        'error occurred',
        'Error in processing',
        'fatal error happened',
        'Fatal: system crash',
        'FATAL connection lost',
        'ERROR: --- Task my:task failed ---'
      ]

      test_cases.each do |error_line|
        lines = ['INFO: Start', error_line, 'INFO: End']
        expect(subject.send(:has_errors?, lines)).to be true
      end
    end

    it 'returns false when no error patterns present' do
      lines_without_error = ['INFO: Starting', 'INFO: Processing', 'INFO: Done']

      expect(subject.send(:has_errors?, lines_without_error)).to be false
    end
  end

  describe 'SCORING_PATTERNS constant' do
    it 'is defined and frozen' do
      expect(described_class::SCORING_PATTERNS).to be_frozen
    end

    it 'contains pattern hashes with required keys' do
      expect(described_class::SCORING_PATTERNS).to all(have_key(:pattern).and(have_key(:score)))
    end

    it 'has regex patterns' do
      described_class::SCORING_PATTERNS.each do |pattern_hash|
        expect(pattern_hash[:pattern]).to be_a(Regexp)
      end
    end

    it 'has numeric scores' do
      described_class::SCORING_PATTERNS.each do |pattern_hash|
        expect(pattern_hash[:score]).to be_a(Numeric)
      end
    end
  end

  describe 'Kernel overwrite' do
    let(:buffer) { StringIO.new }

    before do
      f = file_double
      allow(File).to receive(:open).with(expected_path, 'w').once.and_return(f)
      allow(f).to receive(:write) { |d| buffer.write(d) }
      allow(f).to receive(:size).and_return(buffer.size)
    end

    it 'does not overwrite by default' do
      expect { puts "hi" }.to output("hi\n").to_stdout
      expect { warn "hi" }.to output("hi\n").to_stderr
    end

    it "writes to the current thread's TaskLogger" do
      described_class.set_current!(subject)

      expect { puts "hi" }.not_to output.to_stdout
      expect { warn "hi" }.not_to output.to_stderr
      expect(buffer.string).to eq("hihi\n")

      expect do
        Thread.new do
          expect { puts "hi" }.to output("hi\n").to_stdout
          expect { warn "hi" }.to output("hi\n").to_stderr
        end.join

        described_class.set_current!(nil)

        expect { puts "hi" }.to output("hi\n").to_stdout
        expect { warn "hi" }.to output("hi\n").to_stderr
      end.not_to change { buffer.string }
    end
  end

  def file_double(**args)
    instance_double(File, :sync= => true, **args)
  end
end
