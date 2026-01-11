# frozen_string_literal: true

module KDK
  module Command
    # `kdk sandbox` helps users create a sandbox data environment based
    # on a working database (called "head") from the default branch.
    #
    # A sandbox allows working on changes with a database schema that
    # diverges from the default branch. After work on a feature branch is
    # complete, the sandbox can be discarded and is replaced by the head.
    class Sandbox < BaseCommand
      SUBCOMMANDS = %w[
        enable
        disable
        status
        reset
      ].freeze

      help 'Create an ephemeral database sandbox'

      def run(args = [])
        arg = args.first
        return print_help if arg.nil?

        return print_help(arg) unless SUBCOMMANDS.include?(arg)

        send(:"#{arg}!") # rubocop:disable KhulnasoftSecurity/PublicSend -- see safety check above
      end

      def print_help(arg = nil)
        unless arg.nil?
          message = "#{arg} is not a sub-command."

          correct = DidYouMean::SpellChecker.new(dictionary: SUBCOMMANDS).correct(arg).first
          unless correct.nil?
            correct = out.wrap_in_color(correct, out::COLOR_CODE_YELLOW)
            message << " Did you mean #{correct}?"
          end

          out.warn(message)
        end

        out.info("Usage: kdk sandbox <#{SUBCOMMANDS.join('|')}>")

        true
      end

      private

      def enable!
        out.puts('Enabling sandbox...')
        sandbox_manager.enable!
        out.success('Sandbox has been enabled.')

        true
      end

      def disable!
        out.puts('Disabling sandbox...')
        sandbox_manager.disable!
        out.success("Sandbox has been disabled.")

        true
      end

      def status!
        status = sandbox_manager.status
        out.puts "Sandbox status is #{out.wrap_in_color(status, out::COLOR_CODE_YELLOW)}."

        if status == :broken
          out.puts "Missing data directories: #{sandbox_manager.missing_sources}"
          out.puts "Consider running #{out.wrap_in_color('kdk reset-data (--fast)', out::COLOR_CODE_YELLOW)} to reset your database."
        end

        true
      end

      def reset!
        out.puts('Recreating sandbox from head database...')
        sandbox_manager.reset!
        out.success('Sandbox was recreated from head.')

        true
      end
    end
  end
end
