# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/migration/update_large_table'

RSpec.describe Rubocop::Cop::Migration::UpdateLargeTable do
  let(:tables) { %i[usage_data version_checks] }
  let(:deny_methods) { %i[rename_column_concurrently add_column_with_default] }
  let(:cop_config) do
    {
      'DeniedTables' => tables,
      'DeniedMethods' => deny_methods
    }
  end

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'with large tables' do
      using RSpec::Parameterized::TableSyntax

      where(:table, :update_method) do
        :usage_data | 'add_column_with_default'
        :usage_data | 'rename_column_concurrently'
      end

      with_them do
        it "registers an offense" do
          code = "#{update_method} :#{table}, :column, default: true"

          expect_offense(<<~RUBY)
            #{code}
            #{'^' * code.length} Using `#{update_method}` on the `#{table}` table will take a long time to complete, and should be avoided unless absolutely necessary
          RUBY
        end
      end
    end

    it 'registers no offense for non-denied tables' do
      expect_no_offenses(<<~RUBY)
        add_column_with_default :table, :column, default: true
      RUBY
    end

    it 'registers no offense for non-denied methods' do
      table = tables.sample

      expect_no_offenses(<<~RUBY)
        some_other_method :#{table}, :column, default: true
      RUBY
    end

    context 'when no denied tables parameter is provided' do
      let(:cop_config) { { 'DeniedMethods' => deny_methods } }

      it 'registers no offense when denied tables config is not provided' do
        table = tables.sample

        expect_no_offenses(<<~RUBY)
          add_column_with_default :#{table}, :column, default: true
        RUBY

        expect(cop).not_to have_received(:in_migration?)
      end
    end

    context 'when denied tables is nil' do
      let(:tables) { nil }

      it 'registers no offense when denied tables config is not provided' do
        table = :usage_data

        expect_no_offenses(<<~RUBY)
          add_column_with_default :#{table}, :column, default: true
        RUBY

        expect(cop).not_to have_received(:in_migration?)
      end
    end

    context 'when no denied methods parameter is provided' do
      let(:cop_config) { { 'DeniedTables' => tables } }

      it 'registers no offense when denied methods config is not provided' do
        table = tables.sample

        expect_no_offenses(<<~RUBY)
          add_column_with_default :#{table}, :column, default: true
        RUBY

        expect(cop).not_to have_received(:in_migration?)
      end
    end

    context 'when denied methods is nil' do
      let(:deny_methods) { nil }

      it 'registers no offense when denied methods config is not provided' do
        table = :usage_data

        expect_no_offenses(<<~RUBY)
          add_column_with_default :#{table}, :column, default: true
        RUBY

        expect(cop).not_to have_received(:in_migration?)
      end
    end
  end

  context 'when outside of migration' do
    let(:table) { tables.sample }

    it 'registers no offense for add_column_with_default' do
      expect_no_offenses(<<~RUBY)
          add_column_with_default :#{table}, :column, default: true
      RUBY
    end

    it 'registers no offense for rename_column_concurrently' do
      expect_no_offenses(<<~RUBY)
          rename_column_concurrently :#{table}, :column, default: true
      RUBY
    end
  end
end
