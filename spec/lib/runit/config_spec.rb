# frozen_string_literal: true

RSpec.describe Runit::Config do
  let(:kdk_root) { Pathname.new(Dir.mktmpdir(nil, temp_path)) }
  let(:templates_path) { kdk_root.join('support/templates') }
  let(:real_templates_path) { temp_path.parent.join('support/templates') }
  let(:service_redis) { instance_double(KDK::Services::Base, name: 'redis', command: 'redis-server', env: {}) }
  let(:service_postgresql) do
    instance_double(KDK::Services::Base, name: 'postgresql', command: 'postgresql-server', env: {})
  end

  subject { described_class.new(kdk_root) }

  before do
    templates_path.mkpath
    FileUtils.cp_r(real_templates_path, templates_path.parent)
  end

  after do
    FileUtils.rm_rf(kdk_root)
  end

  describe '#stale_service_links' do
    it 'removes unknown symlinks from the services directory' do
      services_dir = kdk_root.join('services')
      service_mock = Struct.new(:name)

      enabled_service_names = %w[svc1 svc2]
      all_services = %w[svc1 svc2 stale]

      enabled_services = enabled_service_names.map { |name| service_mock.new(name) }

      FileUtils.mkdir_p(services_dir)

      all_services.each do |entry|
        File.symlink('/tmp', services_dir.join(entry))
      end

      FileUtils.touch(services_dir.join('should-be-ignored'))

      stale_collection = [services_dir.join('stale')]
      expect(subject.stale_service_links(enabled_services)).to eq(stale_collection)
    end
  end

  describe '#render' do
    let(:services) { [service_redis, service_postgresql] }

    before do
      allow(subject).to receive(:create_runit_service)
      allow(subject).to receive(:create_runit_down)
      allow(subject).to receive(:create_runit_control_t)
      allow(subject).to receive(:create_runit_log_service)
      allow(subject).to receive(:create_runit_log_config)
      allow(subject).to receive(:enable_runit_service)
    end

    context 'directory creation' do
      it 'creates services and log directories when they do not exist' do
        expect(File.exist?(subject.services_dir)).to be false
        expect(File.exist?(subject.log_dir)).to be false

        subject.render(services: services)

        expect(File.exist?(subject.services_dir)).to be true
        expect(File.directory?(subject.services_dir)).to be true
        expect(File.exist?(subject.log_dir)).to be true
        expect(File.directory?(subject.log_dir)).to be true
      end

      it 'creates services and log directories even when they already exist' do
        FileUtils.mkdir_p(subject.services_dir)
        FileUtils.mkdir_p(subject.log_dir)

        subject.render(services: services)

        expect(File.directory?(subject.services_dir)).to be true
        expect(File.directory?(subject.log_dir)).to be true
      end
    end

    context 'service processing' do
      it 'processes each service in correct order with correct parameters' do
        # max_service_length is 10 ("postgresql".size) and indices are 0 and 1
        expect(subject).to receive(:create_runit_service).with(service_redis).ordered
        expect(subject).to receive(:create_runit_down).with(service_redis).ordered
        expect(subject).to receive(:create_runit_control_t).with(service_redis).ordered
        expect(subject).to receive(:create_runit_log_service).with(service_redis).ordered
        expect(subject).to receive(:create_runit_log_config).with(service_redis, 10, 0).ordered
        expect(subject).to receive(:enable_runit_service).with(service_redis).ordered

        expect(subject).to receive(:create_runit_service).with(service_postgresql).ordered
        expect(subject).to receive(:create_runit_down).with(service_postgresql).ordered
        expect(subject).to receive(:create_runit_control_t).with(service_postgresql).ordered
        expect(subject).to receive(:create_runit_log_service).with(service_postgresql).ordered
        expect(subject).to receive(:create_runit_log_config).with(service_postgresql, 10, 1).ordered
        expect(subject).to receive(:enable_runit_service).with(service_postgresql).ordered

        subject.render(services: services)
      end
    end

    context 'cleanup' do
      it 'removes stale service links after processing services' do
        FileUtils.mkdir_p(subject.services_dir)
        stale_link = subject.services_dir.join('old_service')
        File.symlink('/tmp', stale_link)
        expect(File.exist?(stale_link)).to be true

        subject.render(services: services)

        expect(File.exist?(stale_link)).to be false
      end
    end

    context 'edge cases' do
      it 'handles empty services array gracefully' do
        expect { subject.render(services: []) }.not_to raise_error

        expect(File.directory?(subject.services_dir)).to be true
        expect(File.directory?(subject.log_dir)).to be true
      end

      it 'does not call service processing methods when services array is empty' do
        expect(subject).not_to receive(:create_runit_service)
        expect(subject).not_to receive(:create_runit_down)
        expect(subject).not_to receive(:create_runit_control_t)
        expect(subject).not_to receive(:create_runit_log_service)
        expect(subject).not_to receive(:create_runit_log_config)
        expect(subject).not_to receive(:enable_runit_service)

        subject.render(services: [])
      end

      it 'still performs cleanup when services array is empty' do
        expect(subject).to receive(:stale_service_links).with([]).and_return([])
        subject.render(services: [])
      end
    end
  end

  describe '#create_runit_service' do
    let(:service) { service_redis }

    it 'creates run and finish executable files for provided service instance' do
      expect(subject).to receive(:render_template)
        .with('runit/run.sh.erb', service_instance: service, redacted_command: anything, sv_dir: subject.sv_dir(service))
        .and_return('run_content')
      expect(subject).to receive(:write_executable_file)
        .with(subject.sv_dir(service).join('run'), 'run_content')

      expect(subject).to receive(:render_template)
        .with('runit/finish.sh.erb', service_instance: service, redacted_command: anything, sv_dir: subject.sv_dir(service))
        .and_return('finish_content')
      expect(subject).to receive(:write_executable_file)
        .with(subject.sv_dir(service).join('finish'), 'finish_content')

      subject.create_runit_service(service)
    end
  end

  describe '#create_runit_down' do
    let(:service) { service_redis }

    it 'creates a down file for the provided service instance' do
      expect(subject).to receive(:write_readonly_file)
        .with(subject.sv_dir(service).join('down'), '')

      subject.create_runit_down(service)
    end
  end

  describe '#create_runit_control_t' do
    let(:service) { service_redis }

    it 'creates a control/t file for the provided service instance' do
      expect(subject).to receive(:render_template)
        .with('runit/control/t.rb.erb', pid_path: subject.sv_dir(service).join('supervise/pid'), term_signal: 'TERM')
        .and_return('control_t_content')
      expect(subject).to receive(:write_executable_file)
        .with(subject.sv_dir(service).join('control/t'), 'control_t_content')

      subject.create_runit_control_t(service)
    end
  end

  describe '#create_runit_log_service' do
    let(:service) { service_redis }

    it 'creates a log/run file for the provided service instance' do
      expect(subject).to receive(:render_template)
        .with('runit/log/run.sh.erb', service_log_dir: subject.log_dir.join('redis'))
        .and_return('log_run_content')
      expect(subject).to receive(:write_executable_file)
        .with(subject.sv_dir(service).join('log/run'), 'log_run_content')
      subject.create_runit_log_service(service)
    end
  end

  describe '#create_runit_log_config' do
    let(:service) { service_redis }

    it 'creates a log/config file for the provided service instance' do
      expect(subject).to receive(:render_template)
        .with('runit/log/config.erb', log_prefix: anything, log_label: anything, reset_color: anything, service_instance: service)
        .and_return('log_config_content')
      expect(subject).to receive(:write_readonly_file)
        .with(subject.log_dir.join('redis/config'), 'log_config_content')

      subject.create_runit_log_config(service, 10, 0)
    end
  end

  describe '#enable_runit_service' do
    let(:service) { service_redis }

    it 'creates a symlink in the services directory for the provided service instance' do
      expect(FileUtils).to receive(:ln_sf)
        .with(subject.sv_dir(service), subject.services_dir.join('redis'))

      subject.enable_runit_service(service)
    end
  end

  describe '#write_file' do
    let(:path) { kdk_root.join('test/test.txt') }
    let(:content) { 'test content' }

    after do
      FileUtils.rm_rf(path.dirname)
    end

    it 'creates parent directory if it does not exist' do
      expect(File.exist?(path.dirname)).to be false

      subject.write_file(path, content)

      expect(File.exist?(path.dirname)).to be true
      expect(File.directory?(path.dirname)).to be true
    end

    it 'does not rewrite file when content is identical' do
      FileUtils.mkdir_p(path.dirname)
      FileUtils.touch(path)
      File.write(path, content)
      modified_time = File.mtime(path)

      subject.write_file(path, content)

      expect(File.mtime(path)).to eq(modified_time)
      expect(File.read(path)).to eq(content)
    end

    it 'rewrites file when content differs' do
      FileUtils.mkdir_p(path.dirname)
      FileUtils.touch(path)
      File.write(path, 'old content')

      subject.write_file(path, content)

      expect(File.read(path)).to eq(content)
    end

    it 'rescues Errno::ETXTBSY and returns nil' do
      allow(File).to receive(:write).and_raise(Errno::ETXTBSY)
      expect(subject.write_file(path, content)).to be_nil
    end
  end

  describe '#write_executable_file' do
    let(:path) { kdk_root.join('test/executable') }
    let(:content) { '#!/bin/bash \n echo "test" \n' }

    it 'writes the file with executable permission' do
      subject.write_executable_file(path, content)

      expect(File.exist?(path)).to be true
      expect(File.stat(path).mode & 0o777).to eq(0o755)
      expect(File.read(path)).to eq(content)
    end
  end

  describe '#write_readonly_file' do
    let(:path) { kdk_root.join('test/readonly') }
    let(:content) { 'test content' }

    it 'writes the file with readonly permission' do
      subject.write_readonly_file(path, content)

      expect(File.exist?(path)).to be true
      expect(File.stat(path).mode & 0o777).to eq(0o644)
      expect(File.read(path)).to eq(content)
    end
  end
end
