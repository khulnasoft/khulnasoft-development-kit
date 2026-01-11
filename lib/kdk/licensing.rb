# frozen_string_literal: true

require 'json'

module KDK
  class Licensing
    LicensingPasswordVaultError = Class.new(StandardError)
    LicensingActivationError = Class.new(StandardError)

    def initialize
      @license_edition = config.kdk.license_provisioning.edition
      @khulnasoft_license_type = config.kdk.license_provisioning.khulnasoft.tier
      @duo_license_type = config.kdk.license_provisioning.duo.tier
    end

    def activate
      provision_khulnasoft_license
      activate_khulnasoft_license
    end

    private

    attr_reader :license_edition, :khulnasoft_license_type, :duo_license_type

    def config
      KDK.config
    end

    def provision_khulnasoft_license
      if matching_license?
        out.puts("Matching KhulnaSoft license file found: #{license_file_path}")
        return
      end

      create_or_update_license_file
    end

    def activate_khulnasoft_license
      result = KDK::Shellout.new("bin/rails r #{KDK.root.join('lib/support/activate_khulnasoft_license.rb')} #{license_file_path}", chdir: KDK.config.khulnasoft.dir).run
      return unless result.include?('Error')

      raise LicensingActivationError.new, result
    end

    def create_or_update_license_file
      out.puts "Creating or updating the local KhulnaSoft license"

      license_json = {
        activation_code: fetch_vault('activation_code'),
        expiration_date: Time.at(fetch_vault('expiration_date').to_i).to_datetime.to_date.iso8601,
        edition: license_edition,
        khulnasoft_tier: khulnasoft_license_type,
        duo_tier: duo_license_type.to_s
      }

      File.write(license_file_path, license_json.to_json)
      out.puts "Successfully updated the local KhulnaSoft license: #{license_file_path}"
    end

    def fetch_vault(attribute)
      result = KDK::Shellout.new("op read '#{vault_base_path}/#{attribute}'").run
      raise LicensingPasswordVaultError.new, "Empty response from vault for #{attribute}" if result.nil? || result.strip.empty?

      result
    rescue StandardError => e
      raise LicensingPasswordVaultError.new, "Failed to fetch the license from the password vault for #{vault_base_path}/#{attribute}: #{e.message}"
    end

    def matching_license?
      return false unless File.exist?(license_file_path)

      license_details = JSON.parse(File.read(license_file_path), symbolize_names: true)

      Date.parse(license_details[:expiration_date]) > Date.today &&
        license_details[:khulnasoft_tier] == khulnasoft_license_type &&
        license_details[:duo_tier] == duo_license_type
    end

    def license_file_path
      KDK.root.join('.khulnasoft_license')
    end

    def vault_base_path
      return "op://Engineering/KhulnaSoft_#{license_edition}_#{khulnasoft_license_type}" if duo_license_type.empty?

      "op://Engineering/KhulnaSoft_#{license_edition}_#{khulnasoft_license_type}_Duo_#{duo_license_type}"
    end

    def out
      KDK::Output
    end
  end
end
