# frozen_string_literal: true

require_relative '../kdk/task_helpers'

desc 'Run KhulnaSoft migrations'
task 'khulnasoft-db-migrate' do
  puts
  raise "Migrating failed." unless KDK::TaskHelpers::RailsMigration.new.migrate
end
