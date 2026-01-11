# frozen_string_literal: true

require 'base64'

module KDK
  # Reads the version file and returns its version or an empty string if it doesn't exist.
  module ConfigHelper
    extend self

    def generate_dn(common_name, organizational_unit)
      name = OpenSSL::X509::Name.new(
        [
          ['CN', common_name],
          ['OU', organizational_unit]
        ]
      )

      Base64.strict_encode64(name.to_der)
    end

    def version_from(config, path)
      full_path = config.kdk_root.join(path)
      return '' unless full_path.exist?

      version = full_path.read.chomp
      process_version(version)
    end

    private

    def process_version(version)
      # Returns commit hash as is
      return version if version.length == 40

      "v#{version}"
    end
  end
end
