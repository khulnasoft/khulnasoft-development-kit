# frozen_string_literal: true

require 'simplecov'
require 'simplecov-html'
require 'simplecov-cobertura' if ENV['CI']

ENV['SIMPLECOV_MINIMUM_COVERAGE'] ||= ENV['CI']

SimpleCov.start do
  load_profile 'test_frameworks'

  formatters = [SimpleCov::Formatter::HTMLFormatter]
  formatters << SimpleCov::Formatter::CoberturaFormatter if ENV['CI']

  self.formatters = formatters

  # Enforce minimum coverage only CI when all specs are run.
  # This prevent specs to fail if run individually.
  minimum_coverage 100 if ENV['SIMPLECOV_MINIMUM_COVERAGE']
end
