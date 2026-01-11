# frozen_string_literal: true

# KhulnaSoft Development Kit (KDK) Rakefile
#
# This file bootstraps the Rake environment for KDK, loading custom task
# extensions and helper methods. It should not be invoked directly with
# `bundle exec rake`; instead use `kdk rake [task]`.
#
# Custom Extensions:
# - TaskWithSpinner: Provides visual feedback during task execution
# - TaskWithLogger: Captures and manages task output
# - TaskWithTelemetry: Tracks task execution metrics

# Ensure we're using a compatible Ruby version
if RUBY_VERSION.start_with?('2')
  abort(<<~ERROR)
    Error: You are using Ruby #{RUBY_VERSION}, which is not compatible with KDK.

    This is most likely a legacy Ruby version provided by your operating system.

    By default, KDK uses mise to manage tools like Ruby. Ensure that mise is activated.

    Read how: https://mise.jdx.dev/getting-started.html#activate-mise
  ERROR
end

# Add project lib directory to load path
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

# Ruby Standard Library dependencies
require 'fileutils'

# Project Dependencies
begin
  require 'rake/clean'
  require 'kdk'
  require 'git/configure'
rescue LoadError => e
  abort(<<~ERROR)
    Error: Failed to load required dependencies: #{e.message}

    Please ensure you have run:
      bundle install
  ERROR
end

# Add custom rake tasks directory
Rake.add_rakelib File.expand_path('lib/tasks', __dir__)

# Required to set task "name - comment"
Rake::TaskManager.record_task_metadata = true

# Helper method to create a task with spinner enabled
#
# @example
#   spinner_task :my_task do
#     # Task implementation
#   end
#
# @param args [Array] Arguments passed to Rake::Task.define_task
# @return [Rake::Task] The created task with spinner enabled
def spinner_task(...)
  task(...).tap(&:enable_spinner!)
end

# Extend Rake::Task with custom behaviors
# Order matters: prepended modules are executed in reverse order
begin
  Rake::Task.prepend(Support::Rake::TaskWithSpinner)
  Rake::Task.prepend(Support::Rake::TaskWithLogger)
  Rake::Task.prepend(Support::Rake::TaskWithTelemetry)
rescue NameError => e
  abort(<<~ERROR)
    Error: Failed to load custom Rake extensions: #{e.message}

    This likely indicates a problem with the Support::Rake modules.
    Please check that all files in lib/support/rake/ are present.
  ERROR
end

# Warn users if they're using bundle exec instead of kdk rake
# Only show warning when running rake commands with bundle exec, not for rspec
if ENV['_']&.end_with?('/bundle') && $PROGRAM_NAME.end_with?('/rake')
  KDK::Output.warn('Please use "kdk rake [...]" instead of "bundle exec rake [...]".')
end
