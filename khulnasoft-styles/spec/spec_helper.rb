# frozen_string_literal: true

require 'bundler/setup'
require 'khulnasoft/styles'

require 'rubocop'
require 'rubocop/rspec/support'
require 'rubocop/rspec/shared_contexts/default_rspec_language_config_context'
require 'rspec-parameterized-table_syntax'

require_relative './simplecov_env' unless ENV['SIMPLECOV'] == '0'

spec_helper_glob = File.expand_path('support/**/*.rb', __dir__)
Dir.glob(spec_helper_glob).each { |helper| require(helper) }

RSpec.configure do |config|
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect # Disable `should`
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect # Disable `should_receive` and `stub`
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Forbid RSpec from monkey patching any of our objects
  config.disable_monkey_patching!

  # We should address configuration warnings when we upgrade
  config.raise_errors_for_deprecations!

  # RSpec gives helpful warnings when you are doing something wrong.
  # We should take their advice!
  config.raise_on_warning = true

  config.define_derived_metadata(file_path: %r{/spec/rubocop/cop/}) do |meta|
    meta[:type] = :cop_spec
  end

  config.define_derived_metadata(file_path: %r{/spec/rubocop/cop/rspec/}) do |meta|
    meta[:type] = :rspec_cop_spec
  end

  config.include_context 'config', type: :cop_spec
  config.include_context 'with default RSpec/Language config', type: :rspec_cop_spec

  config.include RuboCop::RSpec::ExpectOffense
end
