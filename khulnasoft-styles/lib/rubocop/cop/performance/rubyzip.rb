# frozen_string_literal: true

module Rubocop
  module Cop
    module Performance
      # Flags inefficient uses of rubyzip's Zip::File, since when instantiated
      # it reads the file's Central Directory into memory entirely. For zips with many
      # files and directories, this can be very expensive even when the archive's size
      # in bytes is small.
      #
      # See also:
      # - https://github.com/rubyzip/rubyzip/issues/506
      # - https://github.com/rubyzip/rubyzip#notes-on-zipinputstream
      class Rubyzip < RuboCop::Cop::Base
        MSG = 'Be careful when opening or iterating zip files via Zip::File. ' \
          'Zip archives may contain many entries, and their file index is ' \
          'read into memory upon construction, which can lead to ' \
          'high memory use and poor performance. ' \
          'Consider iterating archive entries via Zip::InputStream instead.'

        # @!method reads_central_directory?(node)
        def_node_matcher :reads_central_directory?, <<-PATTERN
          (send
            (const
              (const {nil? (cbase)} :Zip) :File) {:new :open :foreach} ...)
        PATTERN

        def on_send(node)
          return unless reads_central_directory?(node)

          add_offense(node)
        end
      end
    end
  end
end
