# frozen_string_literal: true

module Rubocop
  module Cop
    module Tailwind
      # This prevents utility class names from being built dynamically using string interpolation.
      # Tailwind needs to be able to parse fully qualified names to include the necessary utils in
      # the bundle.
      # @example
      #   # bad
      #   bgColor = "gl-bg-#{palette}-#{variant}"
      #   cssClasses = "gl-#{display} gl-border"
      #   width = "gl-w-1/#{denominator}"
      #
      #   # good
      #   bgColor = "gl-bg-red-800"
      #   cssClasses = "gl-flex gl-border"
      #   width = "gl-w-1/2"
      class StringInterpolation < RuboCop::Cop::Base
        TAILWIND_CSS_CLASS = %r{(^|\s)gl-[a-z0-9\-/]*$}
        MSG = 'String interpolations in CSS utility class names are forbidden. See https://github.com/khulnasoft/khulnasoft-development-kit/tree/main/khulnasoft-styles/-/issues/73.'

        # @!method interpolated_tailwind_class?(node)
        def_node_matcher :interpolated_tailwind_class?, <<~PATTERN
          (dstr
            (str /#{TAILWIND_CSS_CLASS}/)
            (begin ...)
            ...
          )
        PATTERN

        def on_dstr(node)
          return unless interpolated_tailwind_class?(node)

          add_offense(node)
        end
      end
    end
  end
end
