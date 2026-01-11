# frozen_string_literal: true

KHULNASOFT_DUO_TAG = 'khulnasoft--duo'

namespace :runner do
  desc "Set up KhulnaSoft Runner with #{KHULNASOFT_DUO_TAG} tag"
  task :setup do
    unless KDK.config.runner.enabled
      KDK::Output.info('Enabling runner in KDK config...')
      KDK.config.bury!('runner.enabled', true)
      KDK.config.save_yaml!
    end

    unless KDK::Machine.supported?
      KDK::Output.info('Skipping runner setup as this platform is not supported.')
      next
    end

    download_runner_binary
    runner_created = setup_runner_token

    KDK::Command::Reconfigure.new.run if runner_created
  end
end

def download_runner_binary
  runner_binary_path = File.join(KDK.config.kdk_root, 'khulnasoft-runner')

  if File.exist?(runner_binary_path) && File.executable?(runner_binary_path)
    KDK::Output.info('Runner binary already exists, skipping download')
  else
    KDK::Output.info('Downloading runner binary...')
    url = "https://s3.dualstack.us-east-1.amazonaws.com/khulnasoft-runner-downloads/latest/binaries/khulnasoft-runner-#{KDK::Machine.package_platform}"
    sh = KDK::Shellout.new(['curl', '-L', '--output', runner_binary_path, url]).execute

    KDK::Output.abort('Failed to download runner binary') unless sh.success?

    File.chmod(0o755, runner_binary_path)
    KDK::Output.success('Runner binary downloaded')

    KDK.config.bury!('runner.bin', runner_binary_path)
    KDK.config.save_yaml!
  end
end

def setup_runner_token
  existing_token = fetch_duo_runner_token
  if existing_token
    KDK::Output.success("Runner with #{KHULNASOFT_DUO_TAG} tag already exists")
    return false
  end

  config_path = File.join(KDK.config.kdk_root, 'khulnasoft-runner-config.yml')
  KDK::Output.warn("Creating runner will update #{config_path}")
  response = KDK::Output.prompt("Create new runner with #{KHULNASOFT_DUO_TAG} tag? [y/N]", raise_interrupt: true)
  return false unless response.match?(/\Ay(?:es)*\z/i)

  if File.exist?(config_path)
    backup = KDK::Backup.new(config_path)
    backup.backup!
  end

  KDK::Output.info("Creating runner with #{KHULNASOFT_DUO_TAG} tag...")
  token = create_duo_runner
  KDK::Output.abort('Failed to create runner') unless token

  KDK.config.bury!('runner.token', token)
  KDK.config.save_yaml!
  KDK::Output.success("Runner created with #{KHULNASOFT_DUO_TAG} tag and token saved to kdk.yml")

  true
end

def fetch_duo_runner_token
  ruby_code = "runner = Ci::Runner.tagged_with('#{KHULNASOFT_DUO_TAG}').where(runner_type: 'instance_type').first; puts runner&.token"
  cmd = ['bundle', 'exec', 'rails', 'runner', ruby_code]
  result = KDK::Shellout.new(cmd, chdir: KDK.config.khulnasoft.dir).execute(display_output: false)

  return nil unless result.success?

  token = result.read_stdout.strip
  token.empty? ? nil : token
end

def create_duo_runner
  ruby_code = "runner = Ci::Runners::CreateRunnerService.new(user: User.first, params: { runner_type: 'instance_type', description: 'KDK runner', tag_list: ['#{KHULNASOFT_DUO_TAG}'], run_untagged: true }).execute.payload[:runner]; puts runner.token"
  cmd = ['bundle', 'exec', 'rails', 'runner', ruby_code]
  result = KDK::Shellout.new(cmd, chdir: KDK.config.khulnasoft.dir).execute(display_output: false)

  unless result.success?
    KDK::Output.error('Failed to create runner')
    return nil
  end

  token = result.read_stdout.strip
  token.empty? ? nil : token
end
