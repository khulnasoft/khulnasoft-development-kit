# frozen_string_literal: true

RSpec.describe CellManager do
  include ShelloutHelper

  let(:cell_count) { 2 }
  let(:enabled) { true }

  subject { described_class.new }

  before do
    stub_kdk_yaml({
      'cells' => {
        'enabled' => enabled,
        'instance_count' => cell_count
      }
    })
    stub_no_color_env('true')
  end

  shared_examples 'does nothing when cells disabled' do |method, args = []|
    context 'with cells disabled' do
      let(:enabled) { false }

      it 'does nothing' do
        expect_no_kdk_shellout
        expect(KDK::Output).not_to receive(:error)

        expect(subject.method(method).call(*args)).to be(true)
      end
    end

    context 'with no cell instances' do
      let(:cell_count) { 0 }

      it 'does nothing' do
        expect_no_kdk_shellout
        expect(KDK::Output).not_to receive(:error)

        expect(subject.method(method).call(*args)).to be(true)
      end
    end
  end

  shared_examples 'prints error when cell is not set up' do |method, args = []|
    let(:enabled) { true }
    let(:cell_count) { 1 }

    it 'prints an error to run "kdk cells up"', :hide_output do
      expect(Dir).to receive(:exist?).with("#{CellManager::CELL_ROOT}/cell-2").and_return(false)
      expect(KDK::Output).to receive(:error).with('Cell cell-2 doesn’t exist yet, run `kdk cells up` first.')
      expect(subject.method(method).call(*args)).to be(false)
    end
  end

  describe '#up' do
    it_behaves_like 'does nothing when cells disabled', 'up'

    context 'when enabled' do
      let(:cell_2_config) do
        <<~YAML
          port_offset: 12000
          cells:
            enabled: false
            port_offset: 12000
          khulnasoft_topology_service:
            enabled: false
          khulnasoft_http_router:
            enabled: false
          khulnasoft:
            cell:
              id: 2
              name: cell-2
            rails:
              port: #{KDK.config.port}
              hostname: #{KDK.config.hostname}
              session_store:
                unique_cookie_key_postfix: false
                session_cookie_token_prefix: cell-2
            topology_service:
              address: other address
              enabled: true
              ca_file: #{KDK.config.khulnasoft.topology_service.ca_file}
              private_key_file: #{KDK.config.khulnasoft.topology_service.private_key_file}
              certificate_file: #{KDK.config.khulnasoft.topology_service.certificate_file}
        YAML
      end

      let(:cell_3_config) do
        <<~YAML
          port_offset: 12150
          cells:
            enabled: false
            port_offset: 12150
          khulnasoft_topology_service:
            enabled: true
          khulnasoft_http_router:
            enabled: false
          khulnasoft:
            cell:
              id: 3
              name: cell-3
            rails:
              port: #{KDK.config.port}
              hostname: #{KDK.config.hostname}
              session_store:
                unique_cookie_key_postfix: false
                session_cookie_token_prefix: cell-3
            topology_service:
              address: #{KDK.config.khulnasoft.topology_service.address}
              enabled: true
              ca_file: other ca_file
              private_key_file: #{KDK.config.khulnasoft.topology_service.private_key_file}
              certificate_file: #{KDK.config.khulnasoft.topology_service.certificate_file}
        YAML
      end

      let(:cell_4_config) do
        <<~YAML
          port_offset: 12300
          cells:
            enabled: false
            port_offset: 12300
          khulnasoft_topology_service:
            enabled: false
          khulnasoft_http_router:
            enabled: false
          khulnasoft:
            cell:
              id: 4
              name: cell-4
            rails:
              hostname: #{KDK.config.hostname}
              port: #{KDK.config.port}
              session_store:
                unique_cookie_key_postfix: false
                session_cookie_token_prefix: cell-4
            topology_service:
              address: #{KDK.config.khulnasoft.topology_service.address}
              enabled: true
              ca_file: #{KDK.config.khulnasoft.topology_service.ca_file}
              private_key_file: #{KDK.config.khulnasoft.topology_service.private_key_file}
              certificate_file: #{KDK.config.khulnasoft.topology_service.certificate_file}
        YAML
      end

      before do
        stub_kdk_yaml <<~YAML
          khulnasoft_http_router:
            enabled: true
          khulnasoft_topology_service:
            enabled: true
          khulnasoft:
            rails:
              session_store:
                unique_cookie_key_postfix: false
                session_cookie_token_prefix: cell-1
          cells:
            enabled: true
            instance_count: 3
            instances:
            - config:
                khulnasoft:
                  topology_service:
                    address: other address
            - config:
                khulnasoft:
                  topology_service:
                    ca_file: other ca_file
                khulnasoft_topology_service:
                  enabled: true
            - # cell 4 has no overrides
        YAML

        allow_any_instance_of(KDK::PostgresqlUpgrader).to receive('bin_path_or_fallback').and_return(nil)
        allow(Dir).to receive(:exist?).and_call_original
      end

      context 'when cells exist' do
        it 'writes cell specific configuration', :aggregate_failures, :hide_output do
          stub_cell_exists('cell-2')
          expect_kdk_cells_shellout('cell-2', 'reconfigure')
          expect_kdk_config('cell-2', cell_2_config)

          stub_cell_exists('cell-3')
          expect_kdk_cells_shellout('cell-3', 'reconfigure')
          expect_kdk_config('cell-3', cell_3_config)

          stub_cell_exists('cell-4')
          expect_kdk_cells_shellout('cell-4', 'reconfigure')
          expect_kdk_config('cell-4', cell_4_config)

          subject.up
        end

        context 'when cells do not exist', :hide_output do
          it 'writes cell specific configuration' do
            stub_cell_exists('cell-2', exists: false)
            stub_cell_exists('cell-2', sub_directory: 'khulnasoft', exists: false)
            expect_kdk_command('git', 'clone', KDK.root.to_s, "#{CellManager::CELL_ROOT}/cell-2")
            expect_kdk_cells_shellout('cell-2', "install khulnasoft_repo=#{KDK.root}/khulnasoft")
            expect_kdk_cells_shellout('cell-2', 'reconfigure')
            expect_kdk_config('cell-2', cell_2_config)

            stub_cell_exists('cell-3', exists: false)
            stub_cell_exists('cell-3', sub_directory: 'khulnasoft', exists: false)
            expect_kdk_command('git', 'clone', KDK.root.to_s, "#{CellManager::CELL_ROOT}/cell-3")
            expect_kdk_cells_shellout('cell-3', "install khulnasoft_repo=#{KDK.root}/khulnasoft")
            expect_kdk_cells_shellout('cell-3', 'reconfigure')
            expect_kdk_config('cell-3', cell_3_config)

            stub_cell_exists('cell-4', exists: false)
            stub_cell_exists('cell-4', sub_directory: 'khulnasoft', exists: false)
            expect_kdk_command('git', 'clone', KDK.root.to_s, "#{CellManager::CELL_ROOT}/cell-4")
            expect_kdk_cells_shellout('cell-4', "install khulnasoft_repo=#{KDK.root}/khulnasoft")
            expect_kdk_cells_shellout('cell-4', 'reconfigure')
            expect_kdk_config('cell-4', cell_4_config)

            subject.up
          end
        end
      end

      def expect_kdk_config(cell_name, expected_yaml)
        expected_yaml = YAML.safe_load(expected_yaml)
        expect(File).to receive(:write)
          .with("#{CellManager::CELL_ROOT}/#{cell_name}/kdk.yml", be_a_kind_of(String)).twice do |_file, content|
            actual_yaml = YAML.safe_load(content)
            expect(actual_yaml).to match(expected_yaml) if actual_yaml
          end
        expect(File).to receive(:read).with("#{CellManager::CELL_ROOT}/#{cell_name}/kdk.yml").and_return('')
      end
    end
  end

  describe '#update' do
    it_behaves_like 'does nothing when cells disabled', 'update'
    it_behaves_like 'prints error when cell is not set up', 'update'

    context 'with cells enabled' do
      it 'updates every cell' do
        stub_cell_exists('cell-2')
        stub_cell_exists('cell-3')

        expect_kdk_cells_shellout('cell-2', 'update')
        expect_kdk_cells_shellout('cell-3', 'update')

        expect { subject.update }.to output(/Updating cell cell-2\n.*Updating cell cell-3/m).to_stdout
      end

      context 'when a cell does not exist' do
        it 'prints an error' do
          stub_cell_exists('cell-2')
          stub_cell_exists('cell-3', exists: false)

          expect_kdk_cells_shellout('cell-2', 'update')

          expect { subject.update }.to output(/Updating cell cell-2\n.*Updating cell cell-3/m).to_stdout.and output(/Cell cell-3 doesn’t exist yet, run `kdk cells up` first./).to_stderr
        end
      end

      context 'when the first update fails' do
        it 'skips subsequent updates' do
          stub_cell_exists('cell-2')
          stub_cell_exists('cell-3')

          expect_kdk_cells_shellout('cell-2', 'update', success: false)

          expect { subject.update }.to output(/Updating cell cell-2\n$/).to_stdout
        end
      end
    end
  end

  describe '#start' do
    it_behaves_like 'does nothing when cells disabled', 'start'
    it_behaves_like 'prints error when cell is not set up', 'start'

    context 'with cells enabled' do
      it 'starts every cell' do
        stub_cell_exists('cell-2')
        stub_cell_exists('cell-3')

        expect_kdk_cells_shellout('cell-2', 'start')
        expect_kdk_cells_shellout('cell-3', 'start')

        expect { subject.start }.not_to output.to_stderr
      end
    end
  end

  describe '#stop' do
    it_behaves_like 'does nothing when cells disabled', 'stop'
    it_behaves_like 'prints error when cell is not set up', 'stop'

    context 'with cells enabled' do
      it 'stops every cell' do
        stub_cell_exists('cell-2')
        stub_cell_exists('cell-3')

        expect_kdk_cells_shellout('cell-2', 'stop')
        expect_kdk_cells_shellout('cell-3', 'stop')

        expect { subject.stop }.not_to output.to_stderr
      end
    end
  end

  describe '#restart' do
    it_behaves_like 'does nothing when cells disabled', 'restart'
    it_behaves_like 'prints error when cell is not set up', 'restart'

    context 'with cells enabled' do
      it 'restarts every cell' do
        stub_cell_exists('cell-2')
        stub_cell_exists('cell-3')

        expect_kdk_cells_shellout('cell-2', 'restart')
        expect_kdk_cells_shellout('cell-3', 'restart')

        expect { subject.restart }.not_to output.to_stderr
      end
    end
  end

  describe '#status' do
    it_behaves_like 'does nothing when cells disabled', 'status'

    context 'with cells enabled' do
      it 'prints the status for every cell' do
        stub_cell_exists('cell-2')
        stub_cell_exists('cell-3')

        expect_kdk_cells_shellout('cell-2', 'status')
        expect_kdk_cells_shellout('cell-3', 'status')

        expect { subject.status }.to output("cell-2\ncell-3\n").to_stdout
      end
    end
  end

  describe '#run_in_cell' do
    context 'with cells disabled' do
      let(:enabled) { false }

      it 'does nothing' do
        expect_no_kdk_shellout
        expect(KDK::Output).not_to receive(:error)

        subject.run_in_cell('cell-2', %w[config list])
      end
    end

    context 'with no cell instances' do
      let(:cell_count) { 0 }

      it 'prints an error' do
        expect_no_kdk_shellout

        expect { subject.run_in_cell('cell-2', %w[config list]) }.to output(
          %r{Cell cell-2 not found. Check doc/howto/cells.md on how to add local cell instances.}
        ).to_stderr
      end
    end

    context 'with cells enabled' do
      context 'with an unknown cell' do
        it 'prints an error' do
          stub_cell_exists('cell-3', exists: false)

          expect_no_kdk_shellout

          expect { subject.run_in_cell('my-cell', %w[config list]) }.to output(
            /Cell my-cell not found. Found: cell-2, cell-3./
          ).to_stderr
        end
      end

      context 'when the cell is not set up yet' do
        it 'prints an error' do
          stub_cell_exists('cell-3', exists: false)
          expect_no_kdk_shellout

          expect { subject.run_in_cell('cell-3', %w[config list]) }.to output(
            /Cell cell-3 doesn’t exist yet, run `kdk cells up` first./
          ).to_stderr
        end
      end

      it 'runs a command in the cell' do
        stub_cell_exists('cell-3')
        expect_kdk_cells_shellout('cell-3', "config list")

        subject.run_in_cell('cell-3', %w[config list])
      end
    end
  end

  describe '#get_config_for' do
    context 'when cell is not configured' do
      it 'raises an error' do
        name = 'not existent'

        expect do
          subject.get_config_for(name)
        end.to raise_error(/No config for cell `#{name}` found/)
      end
    end

    context 'when cell is configured' do
      before do
        stub_kdk_yaml({
          'cells' => {
            'enabled' => enabled,
            'instance_count' => 1,
            'instances' => [{
              'config' => {
                'hostname' => 'cell-2.test'
              }
            }]
          }
        })
      end

      it 'returns a config' do
        name = KDK.config.cells.instances.first.name
        config = subject.get_config_for(name)

        expect(config.hostname).to eq('cell-2.test')
      end
    end
  end

  private

  def stub_cell_exists(cell_name, sub_directory: nil, exists: true)
    directory = cell_dir(cell_name)
    directory << "/#{sub_directory}" if sub_directory
    allow(Dir).to receive(:exist?).with(directory).and_return(exists)
  end

  def expect_kdk_cells_shellout(cell_name, arg_str, quiet: false, success: true)
    shellout_double = kdk_shellout_double(success?: success)

    expect_kdk_shellout_command("kdk #{arg_str};", chdir: "#{CellManager::KDK_ROOT}/khulnasoft-cells/#{cell_name}").and_return(shellout_double)
    expect(shellout_double).to receive(:execute).with(display_output: !quiet).and_return(true)
  end

  def expect_kdk_command(*commands, success: true)
    shellout_double = kdk_shellout_double(success?: success)

    expect_kdk_shellout_command(*commands).and_return(shellout_double)
    expect(shellout_double).to receive(:execute).and_return(success)
  end

  def cell_dir(cell_name)
    "#{CellManager::KDK_ROOT}/khulnasoft-cells/#{cell_name}"
  end
end
