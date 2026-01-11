# frozen_string_literal: true

$LOAD_PATH.unshift("#{__dir__}/lib")

# Ruby Standard Library dependencies
require 'fileutils'

# Project Dependencies
require 'rake/clean'
require 'kdk'
require 'git/configure'

Rake.add_rakelib "#{__dir__}/lib/tasks"

# Required to set task "name - comment"
Rake::TaskManager.record_task_metadata = true

def spinner_task(...)
  task(...).tap(&:enable_spinner!)
end

Rake::Task.prepend(Support::Rake::TaskWithSpinner)
Rake::Task.prepend(Support::Rake::TaskWithLogger)
Rake::Task.prepend(Support::Rake::TaskWithTelemetry)

# Only show warning when running rake commands with bundle exec, not for rspec
KDK::Output.warn('Please use "kdk rake [...]" instead of "bundle exec rake [...]".') if ENV['_']&.end_with?('/bundle') && $PROGRAM_NAME.end_with?('/rake')
