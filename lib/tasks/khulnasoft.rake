# frozen_string_literal: true

namespace :khulnasoft do
  desc 'KhulnaSoft: Truncate logs'
  task :truncate_logs, [:prompt] do |_, args|
    if args[:prompt] != 'false'
      KDK::Output.warn("About to truncate khulnasoft/log/* files.")
      KDK::Output.puts(stderr: true)

      next if ENV.fetch('KDK_KHULNASOFT_TRUNCATE_LOGS_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

      prompt_response = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      next unless prompt_response

      KDK::Output.puts(stderr: true)
    end

    result = KDK.config.khulnasoft.log_dir.glob('*').map { |file| file.truncate(0) }.all?(0)
    raise 'Truncation of khulnasoft/log/* files failed.' unless result

    KDK::Output.success('Truncated khulnasoft/log/* files.')
  end

  desc 'KhulnaSoft: Recompile translations'
  task :recompile_translations do
    task = KDK::Execute::Rake.new('gettext:compile')
    state = task.execute_in_khulnasoft(display_output: false)

    # Log rake output to ${khulnasoft_dir}/log/gettext.log
    KDK.config.khulnasoft.log_dir.join('gettext.log').open('w') do |file|
      file.write(state.output)
    end

    state.success?
  end
end
