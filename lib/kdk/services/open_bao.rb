# frozen_string_literal: true

module KDK
  module Services
    class OpenBao < Base
      def name
        'openbao'
      end

      def command
        # Rather than having kdk.yml be a single unified source of
        # configuration for development environments, we opted to
        # generate more files; see discussion in
        # https://github.com/khulnasoft/khulnasoft-development-kit/-/merge_requests/5340.
        #
        # These must be kept in sync w.r.t. database: if these files are
        # removed but the data persisted, the data _will_ be inaccessible and
        # you will have to call kdk reset-openbao-data to reset the PostgreSQL
        # database and reinitialize openbao.
        #
        # Due to a quirk in how CI executes, we only perform these operations
        # if the kdk root directory already exists.
        if File.exist?(config.kdk_root)
          FileUtils.mkdir_p(config.kdk_root.join('openbao'))

          unseal_key_path = config.kdk_root.join('openbao/unseal.key')
          unless File.exist?(unseal_key_path)
            unseal_key = SecureRandom.hex(32)
            File.write(unseal_key_path, unseal_key)
          end

          admin_password_path = config.kdk_root.join('openbao/admin-password.txt')
          if config.openbao.admin_enabled? && !File.exist?(admin_password_path)
            admin_password = SecureRandom.alphanumeric(32)
            File.write(admin_password_path, admin_password)
          end
        end

        config.openbao.__server_command
      end

      def enabled?
        config.openbao.enabled
      end

      def ready_message
        "OpenBao is available at #{listen_address}"
      end

      private

      def listen_address
        klass = URI::HTTP
        klass.build(host: config.hostname, port: config.openbao.port)
      end
    end
  end
end
