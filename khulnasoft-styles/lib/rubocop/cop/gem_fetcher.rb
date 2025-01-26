# frozen_string_literal: true

module Rubocop
  module Cop
    # Prevents usage of the `git` and `github` arguments to `gem` in a
    # `Gemfile` in order to avoid additional points of failure beyond
    # rubygems.org.
    class GemFetcher < RuboCop::Cop::Base
      MSG = 'Do not use gems from git repositories, only use gems from RubyGems or vendored gems. ' \
        'See https://docs.khulnasoft.com/ee/development/gemfile.html#no-gems-fetched-from-git-repositories'

      # See https://bundler.io/guides/git.html#custom-git-sources
      GIT_SOURCES = %i[git github gist bitbucket].freeze

      # @!method gem_option(node)
      def_node_matcher :gem_option, <<~PATTERN
        (send nil? :gem _ ...
          (hash
            <$(pair (sym {#{GIT_SOURCES.map(&:inspect).join(' ')}}) _)
            ...>
          )
        )
      PATTERN

      RESTRICT_ON_SEND = %i[gem].freeze

      def on_send(node)
        pair_node = gem_option(node)
        return unless pair_node

        add_offense(pair_node)
      end
    end
  end
end
