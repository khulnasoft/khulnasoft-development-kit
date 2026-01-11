# frozen_string_literal: true

module KDK
  module Command
    class Help < BaseCommand
      help 'Print this help text'

      # Allow invalid kdk.yml.
      def self.validate_config?
        false
      end

      def self.track_telemetry?(args)
        !args.include?('--completion')
      end

      def run(args = [])
        if args.delete('--completion')
          out.puts KDK::Command::COMMANDS.keys.compact.sort.reject { |a| a.start_with?('-') }
          return true
        end

        KDK::Logo.print
        out.puts <<~HELP
          #{KDK::VERSION}

          Usage:
            kdk <command> [<args>]

          Commands:
          #{command_help}

          # Development admin account: root / 5iveL!fe

        HELP

        true
      end

      private

      def command_help
        commands_with_help = KDK::Command::COMMANDS
          .uniq { |v| v[1].call.name }
          .to_h { |name, command| [out.wrap_in_color(name, out::COLOR_CODE_YELLOW), command.call.help] }
          .select { |_, help| help.any? }
          .sort

        max_length = commands_with_help
          .flat_map { |name, help| help.map { |item| name.size + (item.subcommand&.size || 0) + 1 } }
          .max

        commands_with_help.map do |name, help|
          help.map do |item|
            full_command = "#{name} #{item.subcommand}".ljust(max_length)
            "  #{full_command} # #{item.description}"
          end
        end.join("\n")
      end
    end
  end
end
