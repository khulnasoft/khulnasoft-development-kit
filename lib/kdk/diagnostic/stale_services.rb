# frozen_string_literal: true

module KDK
  module Diagnostic
    class StaleServices < Base
      TITLE = 'Stale Services'

      StaleProcess = Struct.new(:pid, :service, :defunct, keyword_init: true)
      private_constant :StaleProcess

      def success?
        @success ||= ps_command_success? && all_stale_processes.empty?
      end

      def detail
        return if success?

        stale_services_detail
      end

      private

      def ps_command_success?
        @ps_command_success ||= [0, 1].include?(ps_command.exit_code)
      end

      def ps_command
        @ps_command ||= Shellout.new(command).execute(display_output: false, display_error: false)
      end

      def command
        # Find runsv processes with parent PID 1, which means their parent process is no longer running
        @command ||= %(ps -eo pid,ppid,state,command | awk '$2 == 1' | grep -E "runsv (#{service_names.join('|')})" | grep -v grep)
      end

      def service_names
        (KDK::Services.all + KDK::Services.legacy).map(&:name).uniq
      end

      def all_stale_processes
        @all_stale_processes ||=
          if ps_command_success?
            ps_command.read_stdout.split("\n").each_with_object([]) do |line, all|
              # Example: "95010 1 Ss   runsv rails-web"
              match = line.match(/^\s*(?<pid>\d+)\s+\d+\s+(?<state>\S+)\s+runsv\s+(?<service>\S+)/)
              next unless match

              all << StaleProcess.new(pid: match[:pid], service: match[:service], defunct: match[:state].start_with?('Z'))
            end
          else
            []
          end
      end

      def stale_processes
        all_stale_processes.reject(&:defunct)
      end

      def defunct_processes
        all_stale_processes.select(&:defunct)
      end

      def stale_services_detail
        return if success?

        return "Unable to run '#{command}'." if all_stale_processes.empty?

        message = []

        if stale_processes.any?
          message << "The following KDK services appear to be stale:"
          message << ""
          message << stale_processes.map(&:service).join("\n")
          message << ""
          message << "You can try killing them by running 'kdk kill' or:"
          message << ""
          message << " kill #{stale_processes.map(&:pid).join(' ')}"
        end

        if defunct_processes.any?
          message << "" if stale_processes.any?
          message << "The following KDK services are defunct (zombie processes):"
          message << ""
          message << defunct_processes.map { |p| "#{p.pid} - #{p.service}" }.join("\n")
          message << ""
          message << "These services are not running but still show up in the process list."
          message << "Try running 'kdk restart' to remove them."
        end

        message.join("\n")
      end
    end
  end
end
