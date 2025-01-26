# frozen_string_literal: true

module Rubocop
  module Cop
    module Rails
      #  Avoid including `ActionView::Helpers::UrlHelper`.
      #  It adds/overrides ~40 methods while usually only one is needed.
      #  Instead, use the `Khulnasoft::Routing.url_helpers`/`Application.routes.url_helpers`(outside of khulnasoft)
      #  and `ActionController::Base.helpers.link_to`.
      #
      # @example
      #   # bad
      #   class Foo
      #     include ActionView::Helpers::UrlHelper  # <-- includes 40 new methods !
      #
      #     def link_to_something
      #       link_to(...)
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     def link_to_something
      #       url = Khulnasoft::Routing.url_helpers.project_blob_path(...)
      #       ActionController::Base.helpers.link_to(url, "Link text")
      #     end
      #   end
      #
      # See also
      # - https://khulnasoft.com/khulnasoft-org/khulnasoft/-/issues/340567.
      class IncludeUrlHelper < RuboCop::Cop::Base
        MSG = <<~MSG
          Avoid including `ActionView::Helpers::UrlHelper`.
          It adds/overrides ~40 methods while usually only one is needed.
          Instead, use the `Khulnasoft::Routing.url_helpers`/`Application.routes.url_helpers`(outside of khulnasoft)
          and `ActionController::Base.helpers.link_to`.
          See https://khulnasoft.com/khulnasoft-org/khulnasoft/-/issues/340567.
        MSG

        # @!method include_url_helpers_node?(node)
        def_node_matcher :include_url_helpers_node?, <<~PATTERN
          (send nil? :include (const (const (const {nil? cbase} :ActionView) :Helpers) :UrlHelper))
        PATTERN

        def on_send(node)
          add_offense(node) if include_url_helpers_node?(node)
        end
      end
    end
  end
end
