# frozen_string_literal: true

module KDK
  module Hooks
    def self.with_hooks(hooks, name)
      execute_hooks(hooks[:before], "#{name}: before")
      result = block_given? ? yield : true
      execute_hooks(hooks[:after], "#{name}: after")

      result
    end

    def self.execute_hooks(hooks, description)
      hooks.each do |cmd|
        execute_hook_cmd(cmd, description)
      end

      true
    end

    def self.execute_hook_cmd(cmd, description)
      KDK::Output.abort("Cannot execute '#{description}' hook '#{cmd}' as it's invalid") unless cmd.is_a?(String)
      KDK::Output.info("#{description} hook -> #{cmd}")

      sh = Shellout.new(cmd)
      sh.stream

      raise UserInteractionRequired, "Custom hook '#{description}' has failed with code #{sh.exit_code}." unless sh.success?

      true
    rescue Shellout::StreamCommandFailedError => e
      KDK::Output.abort(e.message, e)
    end
  end
end
