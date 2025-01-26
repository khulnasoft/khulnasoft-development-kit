# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/gem_fetcher'

RSpec.describe Rubocop::Cop::GemFetcher do
  let(:msg) do
    'Do not use gems from git repositories, only use gems from RubyGems or vendored gems. See [...]'
  end

  shared_examples 'an offense' do
    it 'registers an offense' do
      source = %(#{git_source}: "https://khulnasoft.com/foo/bar.git")

      expect_offense(<<~RUBY, source: source)
        gem "foo", #{source}
                   ^{source} #{msg}

        gem "foo", ref: 'main', #{source}, required: false
                                ^{source} #{msg}

        gem "foo", "v1.2.3", ref: 'main', #{source}, required: false
                                          ^{source} #{msg}
      RUBY
    end
  end

  where(:git_source) do
    %i[git github gist bitbucket]
  end

  with_them do
    it_behaves_like 'an offense'
  end

  it 'with valid use it does not register an offense' do
    expect_no_offenses(<<~RUBY)
      gem "foo", "1.0.0"
      gem "bar"
      gem "baz", required: false
    RUBY
  end
end
