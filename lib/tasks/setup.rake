# frozen_string_literal: true

desc 'Preflight checks for dependencies'
task 'preflight-checks' do
  checker = KDK::Dependencies::Checker.new(preflight: true)
  checker.check_all

  unless checker.error_messages.empty?
    messages = checker.error_messages.map { |m| m.nil? ? "" : m.dup.prepend('- ') }.join("\n")
    fix = if Utils.executable_exist?('brew')
            "To fix this, run: cd #{KDK.config.kdk_root} && brew bundle install"
          else
            "To fix this, see https://khulnasoft-org.khulnasoft.io/khulnasoft-development-kit/advanced/."
          end

    raise KDK::UserInteractionRequired, "Missing software needed for KDK:\n\n#{messages}\n\n#{fix}"
  end
end

desc 'Preflight Update checks'
task 'preflight-update-checks' do
  postgresql = KDK::Postgresql.new
  if postgresql.installed? && postgresql.upgrade_needed?
    message = <<~MESSAGE
      PostgreSQL data directory is version #{postgresql.current_version} and must be upgraded to version #{postgresql.class.target_version} before KDK can be updated.
    MESSAGE

    KDK::Output.warn(message)

    if ENV['PG_AUTO_UPDATE']
      KDK::Output.warn('PostgreSQL will be auto-updated in 10 seconds. Hit CTRL-C to abort.')
      Kernel.sleep 10
    else
      prompt_response = KDK::Output.prompt("This will run 'support/upgrade-postgresql' to back up and upgrade the PostgreSQL data directory. Are you sure? [y/N]").match?(/\Ay(?:es)*\z/i)
      next unless prompt_response
    end

    postgresql.upgrade

    KDK::Output.success("Successfully ran 'support/upgrade-postgresql' script!")
  end
end

namespace :update do
  desc 'Tool versions update'
  task 'tool-versions' do |t|
    t.skip! unless KDK.config.tool_version_manager.enabled?
    KDK::ToolVersionsUpdater.new.run
  end
end
