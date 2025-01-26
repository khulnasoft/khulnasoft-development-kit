# frozen_string_literal: true

require_relative 'config'

module KDK
  # Config subclass to generate kdk.example.yml
  class ConfigExample < Config
    # Module that stubs reading from the environment
    module Stubbed
      def find_executable!(_bin)
        nil
      end

      def rand(max = 0)
        return max.first if max.is_a?(Range)

        0
      end

      def settings_klass
        ::KDK::ConfigExample::Settings
      end
    end

    # Environment stubbed KDK::ConfigSettings subclass
    class Settings < ::KDK::ConfigSettings
      prepend Stubbed
    end

    prepend Stubbed

    KDK_ROOT = '/home/git/kdk'

    # Avoid messing up the superclass (i.e. `KDK::Config`)
    @attributes = superclass.attributes.dup

    def initialize
      # Override some settings which would otherwise be auto-detected
      yaml = {
        'username' => 'git',
        'git_repositories' => [],
        'restrict_cpu_count' => -1,
        'postgresql' => {
          'bin_dir' => '/usr/local/bin'
        }
      }

      super(yaml: yaml)
    end
  end
end
