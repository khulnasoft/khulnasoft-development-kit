# frozen_string_literal: true

module Rubocop
  module Cop
    module Tailwind
      # This prevents the use of max-width media query Tailwind CSS utility classes unless absolutely necessary.
      # min-width media query Tailwind CSS utility classes should be used instead.
      # @example
      #   # bad
      #   css_classes = ["gl-mt-5", "max-md:gl-mt-3"]
      #   %div{ class: ["gl-mt-5", "max-md:gl-mt-3"] }
      #
      #   # good
      #   css_classes = ["gl-mt-3", "md:gl-mt-5"]
      #   %div{ class: ["gl-mt-3", "md:gl-mt-5"] }
      class MaxWidthMediaQueries < RuboCop::Cop::Base
        TAILWIND_CSS_CLASS = /max-(sm|md|lg|xl):gl-/
        MSG = 'Do not use max-width media query utility classes unless absolutely necessary. ' \
          'Use min-width media query utility classes instead.'

        # @!method max_width_media_query_class?(node)
        def_node_matcher :max_width_media_query_class?, <<~PATTERN
          (str /#{TAILWIND_CSS_CLASS}/)
        PATTERN

        def on_str(node)
          return unless max_width_media_query_class?(node)

          add_offense(node)
        end
      end
    end
  end
end
