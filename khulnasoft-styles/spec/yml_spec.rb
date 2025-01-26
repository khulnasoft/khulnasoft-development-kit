# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe "provided .yml files", :integration do
  let(:present_configurations) { Dir["rubocop-*.yml"] }

  context "without other files" do
    where(:yml) { present_configurations }

    with_them do
      it "runs successfully" do
        _output, error, status = Open3.capture3("bundle exec rubocop -c #{yml}")

        expect(error).to be_empty
        expect(status.exitstatus).not_to eq(2)
      end
    end
  end

  context 'with rubocop-default.yml' do
    let(:yml) { 'rubocop-default.yml' }

    it "load all defined configurations" do
      output, error, status = Open3.capture3("bundle exec rubocop -d -c #{yml}")

      loaded = output.scan(/^Inheriting .*(rubocop.*\.yml)$/).flatten(1)

      expect(present_configurations - [yml]).to match_array(loaded)
      expect(error).to be_empty
      expect(status.exitstatus).not_to eq(2)
    end
  end
end
