# frozen_string_literal: true

module Rubocop
  module Cop
    module Style
      # Identifies places where `map { ... }.to_h` or
      # `Hash[map { ... }]` can be replaced with `to_h { ... }`,
      # saving an intermediate array allocation.
      #
      # @example
      #   # bad
      #   hash.map { |k, v| [v.upcase, k.downcase] }.to_h
      #   hash.collect { |k, v| [v.upcase, k.downcase] }.to_h
      #   Hash[hash.map { |k, v| [v.upcase, k.downcase] }]
      #   Hash[hash.collect { |k, v| [v.upcase, k.downcase] }]
      #   array.map { |x| [x, x + 1] }.to_h
      #
      #   # good
      #   hash.to_h { |k, v| [v.upcase, k.downcase] }
      #   array.to_h { |x| [x, x + 1] }
      #
      # Full credit: https://github.com/eugeneius/rubocop-performance/blob/hash_transformation/lib/rubocop/cop/performance/hash_transformation.rb
      class HashTransformation < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector
        include RuboCop::Cop::RangeHelp

        MSG = 'Use `to_h { ... }` instead of `%<current>s`.'

        # @!method to_h_candidate?(node)
        def_node_matcher :to_h_candidate?, <<~PATTERN
          {
            [(send
              $(block $(send _ {:map :collect}) ...) :to_h) !block_literal?]
            (send (const nil? :Hash) :[]
              $(block $(send _ {:map :collect}) ...))
          }
        PATTERN

        def on_send(node)
          to_h_candidate?(node) do |_block, call|
            range = offense_range(node, call)
            message = message(node, call)
            add_offense(range, message: message) do |corrector|
              block, call = to_h_candidate?(node)

              corrector.remove(after_block(node, block))
              corrector.replace(call.loc.selector, 'to_h')
              corrector.remove(before_block(node, block))
            end
          end
        end

        private

        def offense_range(node, call)
          return node.source_range if node.children.first.const_type?

          range_between(call.loc.selector.begin_pos, node.loc.selector.end_pos)
        end

        def message(node, call)
          current = if node.children.first.const_type?
                      "Hash[#{call.method_name} { ... }]"
                    else
                      "#{call.method_name} { ... }.to_h"
                    end

          format(MSG, current: current)
        end

        def after_block(node, block)
          block.source_range.end.join(node.source_range.end)
        end

        def before_block(node, block)
          node.source_range.begin.join(block.source_range.begin)
        end
      end
    end
  end
end
