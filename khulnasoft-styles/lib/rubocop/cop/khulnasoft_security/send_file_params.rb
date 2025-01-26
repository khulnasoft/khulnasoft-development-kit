# frozen_string_literal: true

module RuboCop
  module Cop
    module KhulnasoftSecurity
      # Check for use of send_file(..., params[], ...)
      #
      # Passing user params to the send_file() method allows directory traversal
      #
      # @example
      #
      #   # bad
      #   send_file("/tmp/myproj/" + params[:filename])
      #
      #   # good (verify directory)

      #   basename = File.expand_path("/tmp/myproj")
      #   filename = File.expand_path(File.join(basename, @file.public_filename))
      #   raise if basename != filename
      #   send_file filename, disposition: 'inline'
      #
      class SendFileParams < RuboCop::Cop::Base
        MSG = 'Do not pass user provided params directly to send_file(), ' \
          'verify the path with file.expand_path() first.'

        # @!method params_node?(node)
        def_node_search :params_node?, <<-PATTERN
           (send (send nil? :params) ... )
        PATTERN

        def on_send(node)
          return unless node.command?(:send_file)
          return unless node.arguments.any? { |e| params_node?(e) }

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
