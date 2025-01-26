# frozen_string_literal: true

require 'fileutils'

module KDK
  module Command
    class DebugInfo < BaseCommand
      NEW_ISSUE_LINK = 'https://github.com/khulnasoft/khulnasoft-development-kit/-/issues/new'
      ENV_WILDCARDS = %w[KDK_.* BUNDLE_.* GEM_.*].freeze
      ENV_VARS = %w[
        PATH LANG LANGUAGE LC_ALL LDFLAGS CPPFLAGS PKG_CONFIG_PATH
        LIBPCREDIR RUBY_CONFIGURE_OPTS
      ].freeze

      def run(_ = [])
        KDK::Output.puts separator
        KDK::Output.info review_prompt
        KDK::Output.puts separator

        KDK::Output.puts "Operating system: #{os_name}"
        KDK::Output.puts "Architecture: #{arch}"
        KDK::Output.puts "Ruby version: #{ruby_version}"
        KDK::Output.puts "KDK version: #{kdk_version}"

        KDK::Output.puts
        KDK::Output.puts 'Environment:'

        ENV_VARS.each do |var|
          KDK::Output.puts "#{var}=#{ENV.fetch(var, nil)}"
        end

        ENV.each do |var, content|
          next unless matches_regex?(var)

          KDK::Output.puts "#{var}=#{content}"
        end

        if kdk_yml_exists?
          KDK::Output.puts
          KDK::Output.puts 'KDK configuration:'
          KDK::Output.puts kdk_yml
        end

        KDK::Output.puts separator

        true
      end

      def os_name
        shellout('uname -a')
      end

      def arch
        shellout('arch')
      end

      def ruby_version
        shellout('ruby --version')
      end

      def node_version
        shellout('node --version')
      end

      def kdk_version
        shellout('git rev-parse --short HEAD', chdir: KDK.root)
      end

      def shellout(cmd, **args)
        Shellout.new(cmd, **args).run
      rescue StandardError => e
        "Unknown (#{e.message})"
      end

      def matches_regex?(var)
        var.match?(combined_env_regex)
      end

      def combined_env_regex
        @combined_env_regex ||= /^#{ENV_WILDCARDS.join('|')}$/
      end

      def kdk_yml
        File.read(KDK::Config::FILE)
      end

      def kdk_yml_exists?
        File.exist?(KDK::Config::FILE)
      end

      def review_prompt
        <<~MESSAGE
          Please review the content below, ensuring any sensitive information such as
             API keys, passwords etc are removed before submitting. To create an issue
             in the KhulnaSoft Development Kit project, use the following link:

             #{NEW_ISSUE_LINK}

        MESSAGE
      end

      def separator
        @separator ||= '-' * 80
      end
    end
  end
end
