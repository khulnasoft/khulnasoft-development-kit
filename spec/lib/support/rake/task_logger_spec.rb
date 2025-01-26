# frozen_string_literal: true

RSpec.describe Support::Rake::TaskLogger do
  let(:task) { instance_double(Rake::Task, name: 'test task') }
  let!(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
  let!(:expected_path) { "#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/test-task.log" }

  subject { described_class.new(task) }

  before do
    allow(FileUtils).to receive(:mkdir_p).with("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279")
    allow(described_class).to receive(:start_time).and_return(now)
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
    it 'creates the log dir' do
      expect(FileUtils).to receive(:mkdir_p).with("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279")

      subject
    end
  end

  describe '#file_path' do
    it 'returns the task- and date-specific file name' do
      expect(subject.file_path).to eq(expected_path)
    end

    context 'when the task name contains filesystem-relevant chracters' do
      let(:task) { instance_double(Rake::Task, name: 'khulnasoft/doc/api/graphql/reference/khulnasoft_schema.json') }
      let!(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
      let!(:expected_path) { "#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/khulnasoft-doc-api-graphql-reference-khulnasoft_schema-json.log" }

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
      expect(subject.file).to be(f)
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
