# frozen_string_literal: true

# KhulnaSoft Development Kit CLI parser / executor
#
# This file is loaded by the 'kdk' command in the gem. This file is NOT
# part of the khulnasoft-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require 'securerandom'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, '.rb')
loader.inflector.inflect(
  {
    'kdk' => 'KDK',
    'http_helper' => 'HTTPHelper',
    'open_ldap' => 'OpenLDAP',
    'test_url' => 'TestURL'
  })
loader.push_dir(__dir__)
loader.setup

# KhulnaSoft Development Kit
module KDK
  StandardErrorWithMessage = Class.new(StandardError)
  HookCommandError = Class.new(StandardError)

  # requires `khulnasoft-development-kit` gem to be at least this version
  REQUIRED_GEM_VERSION = '0.2.18'
  PROGNAME = 'kdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'

  # Entry point for the KDK binary.
  #
  # Do not remove because we need to support that use case where a new KDK binary
  # calls older KDK code.
  def self.main
    setup_rake

    Command.run(ARGV)
  end

  def self.setup_rake
    require 'rake'
    Rake.application.init('rake', %W[--rakefile #{KDK.root}/Rakefile])
    Rake.application.load_rakefile
  end

  def self.config
    @config ||= KDK::Config.load_from_file
  end

  # Return the path to the KDK base path
  #
  # @return [Pathname] path to KDK base directory
  def self.root
    Pathname.new(__dir__).parent
  end

  def self.make(*targets, env: {})
    sh = Shellout.new(MAKE, targets, chdir: KDK.root, env: env)
    sh.stream
    sh
  end
end
