# frozen_string_literal: true

module Khulnasoft
  module Styles
    module Common
      module BannedConstants
        attr_reader :replacements, :message_template, :autocorrect

        def on_const(node)
          constant = node.source.delete_prefix('::')

          return unless replacements.key?(constant)

          replacement = replacements.fetch(constant)
          message = format(message_template, { replacement: replacement })

          add_offense(node, message: message) do |corrector|
            next unless autocorrect

            replacement = "::#{replacement}" if node.source.start_with?("::")

            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
