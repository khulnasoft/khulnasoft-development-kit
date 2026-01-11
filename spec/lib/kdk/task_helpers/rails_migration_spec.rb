# frozen_string_literal: true

RSpec.describe KDK::TaskHelpers::RailsMigration, :hide_stdout do
  include ShelloutHelper

  describe '#migrate' do
    let(:shellout_mock) { kdk_shellout_double(success?: true) }
    let(:rails_migration) { described_class.new }
    let(:project_mock) { instance_double(KDK::Project::Base) }
    let(:main_already_migrated) { false }

    subject(:migrate) { rails_migration.migrate }

    before do
      allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      allow(KDK::Diagnostic::PendingMigrations).to receive_message_chain(:new, :success?).and_return(main_already_migrated)
      allow_any_instance_of(KDK::Postgresql).to receive(:in_recovery?).and_return(in_recovery)
      stub_pg_bindir
      allow(KDK::Project::Base).to receive(:new).and_return(project_mock)
      allow(project_mock).to receive(:with_stashed).and_yield
    end

    context 'when database is not in recovery' do
      let(:in_recovery) { false }

      context 'when already migrated' do
        let(:main_already_migrated) { true }

        it 'does nothing' do
          expect_no_kdk_shellout

          migrate
        end
      end

      it 'migrates the main database' do
        expect_kdk_shellout.with(array_including('db:migrate'), any_args).and_return(shellout_mock)

        migrate
      end

      context 'with geo enabled' do
        before do
          stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => geo_secondary })
        end

        context 'when Geo is a primary' do
          let(:geo_secondary) { false }

          it 'does not migrate the Geo database' do
            allow_kdk_shellout.and_return(shellout_mock)
            expect_no_kdk_shellout.with(array_including('db:migrate:geo'), any_args)

            migrate
          end
        end

        context 'when Geo is a secondary' do
          let(:main_already_migrated) { true }
          let(:geo_secondary) { true }

          it 'migrates the Geo database' do
            stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

            expect_kdk_shellout.with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

            migrate
          end

          it 'does not migrate the main database' do
            stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

            allow_kdk_shellout.and_return(shellout_mock)
            expect_no_kdk_shellout.with(array_including('db:migrate'), any_args)

            migrate
          end
        end
      end

      it 'executes rake tasks within the stashed context' do
        expect_kdk_shellout.with(array_including('db:migrate'), any_args).and_return(shellout_mock)

        expect(project_mock).to receive(:with_stashed).and_yield

        migrate
      end
    end

    context 'when database is in recovery' do
      let(:in_recovery) { true }

      it 'does nothing' do
        expect_no_kdk_shellout

        migrate
      end

      it 'does not migrate the Geo database when Geo is a primary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => false })

        expect_no_kdk_shellout.with(array_including('db:migrate:geo'), any_args)

        migrate
      end

      it 'migrates the Geo database when Geo is a secondary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

        expect_kdk_shellout.with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

        migrate
      end

      it 'uses git stashing when running Geo migrations' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })
        allow_kdk_shellout.and_return(shellout_mock)

        expect(project_mock).to receive(:with_stashed).and_yield

        migrate
      end
    end
  end
end
