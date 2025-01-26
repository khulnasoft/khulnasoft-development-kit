# frozen_string_literal: true

RSpec.describe 'kdk' do
  let!(:kdk_bin_full_path) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'gem', 'bin', 'kdk')) }

  shared_examples 'returns expected output' do
    it 'returns expected output' do
      expect(`#{kdk_bin_full_path} #{command}`).to eql(expected_output)
    end
  end

  shared_examples 'contains expected output' do
    it 'contains expected output' do
      expect(`#{kdk_bin_full_path} #{command}`).to include(expected_output)
    end
  end

  describe 'version' do
    let(:git_sha) { `git rev-parse --short HEAD`.chomp }
    let(:expected_output) { "KhulnaSoft Development Kit 0.2.18 (#{git_sha})\n" }

    %w[version -version --version].each do |variant|
      context variant do
        let(:command) { variant }

        it_behaves_like 'returns expected output'
      end
    end
  end

  describe 'help' do
    let(:expected_output) { "Usage: kdk <command> [<args>]" }

    %w[help -help --help].each do |variant|
      context variant do
        let(:command) { variant }

        it_behaves_like 'contains expected output'
      end
    end
  end
end
