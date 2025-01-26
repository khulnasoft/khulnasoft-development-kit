# frozen_string_literal: true

module Rubocop
  module Cop
    # Ensures a line break around conditional blocks.
    #
    # @example
    #    # bad
    #    do_something
    #    if condition
    #      do_extra_stuff
    #    end
    #    do_something_more
    #
    #    # good
    #    do_something
    #
    #    if condition
    #      do_extra_stuff
    #    end
    #
    #    do_something_more
    #
    #    # bad
    #    do_something
    #    unless condition
    #      do_extra_stuff
    #    end
    #
    #    do_something_more
    #
    #    # good
    #    def a_method
    #      if condition
    #        do_something
    #      end
    #    end
    #
    #    # good
    #    on_block do
    #      if condition
    #        do_something
    #      end
    #    end
    class LineBreakAroundConditionalBlock < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector
      include RuboCop::Cop::RangeHelp

      MSG = 'Add a line break around conditional blocks'

      def on_if(node)
        # This cop causes errors in haml files, so let's skip those
        return if in_haml?(node)
        return if node.single_line?
        return unless node.if? || node.unless?

        corrector_block = lambda do |corrector|
          line = range_by_whole_lines(node.source_range)

          corrector.insert_before(line, "\n") unless previous_line_valid?(node)
          corrector.insert_after(line, "\n") unless last_line_valid?(node)
        end

        add_offense(node, &corrector_block) unless previous_line_valid?(node)
        add_offense(node, &corrector_block) unless last_line_valid?(node)
      end

      private

      def previous_line_valid?(node)
        previous_line(node).empty? ||
          start_clause_line?(previous_line(node)) ||
          method_def_end?(node.parent, previous_line(node)) ||
          block_start?(previous_line(node)) ||
          begin_line?(previous_line(node)) ||
          assignment_line?(previous_line(node)) ||
          rescue_line?(previous_line(node))
      end

      def last_line_valid?(node)
        last_line(node).empty? ||
          end_line?(last_line(node)) ||
          end_clause_line?(last_line(node))
      end

      def previous_line(node)
        processed_source[node.loc.line - 2]
      end

      def last_line(node)
        processed_source[node.loc.last_line]
      end

      def start_clause_line?(line)
        line =~ /^\s*(def|=end|#|module|class|if|unless|else|elsif|ensure|when)/
      end

      def method_def_end?(node, line)
        node.def_type? && /\)\s*(#.*)?$/.match?(line)
      end

      def end_clause_line?(line)
        line =~ /^\s*(#|rescue|else|elsif|when)/
      end

      def begin_line?(line)
        # an assignment followed by a begin or ust a begin
        line =~ /^\s*(@?(\w|\|+|=|\[|\]|\s)+begin|begin)/
      end

      def assignment_line?(line)
        line =~ /^\s*.*=/
      end

      def rescue_line?(line)
        line =~ /^\s*rescue/
      end

      def block_start?(line)
        line.match(/ (do|{)( \|.*?\|)?\s?(#.+)?\z/)
      end

      def end_line?(line)
        line =~ /^\s*(end|})/
      end

      def in_haml?(node)
        node.source_range.source_buffer.name.end_with?('.haml.rb')
      end
    end
  end
end
