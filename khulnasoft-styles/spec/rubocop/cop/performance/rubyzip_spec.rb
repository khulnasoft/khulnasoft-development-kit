# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/performance/rubyzip'

RSpec.describe Rubocop::Cop::Performance::Rubyzip do
  %w[Zip ::Zip].each do |klass|
    context 'when opening rubyzip files' do
      context "when instantiating #{klass} via new" do
        specify do
          expect_offense(<<~RUBY, klass: klass)
            zip = %{klass}::File.new(path_or_io)
                  ^{klass}^^^^^^^^^^^^^^^^^^^^^^ Be careful when opening or iterating zip files via Zip::File. [...]
          RUBY
        end
      end

      context "when instantiating #{klass} via open" do
        specify do
          expect_offense(<<~RUBY, klass: klass)
            zip = %{klass}::File.open(path_or_io)
                  ^{klass}^^^^^^^^^^^^^^^^^^^^^^^ Be careful when opening or iterating zip files via Zip::File. [...]
          RUBY
        end
      end

      context "when iterating rubyzip files with #{klass}::File.foreach" do
        specify do
          expect_offense(<<~RUBY, klass: klass)
            %{klass}::File.foreach(path_or_io) { |e| nil }
            ^{klass}^^^^^^^^^^^^^^^^^^^^^^^^^^ Be careful when opening or iterating zip files via Zip::File. [...]
          RUBY
        end
      end
    end
  end
end
