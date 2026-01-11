# frozen_string_literal: true

AI_GATEWAY_ENV_FILE = File.join(KDK.root, 'khulnasoft-ai-gateway', '.env')
LOG_FILE = File.join(KDK.root, 'log/khulnasoft-ai-gateway/gateway_debug.log')
DEBUG_VARS = {
  'AIGW_LOGGING__LEVEL' => 'debug',
  'AIGW_LOGGING__FORMAT_JSON' => 'false',
  'AIGW_LOGGING__TO_FILE' => LOG_FILE
}.freeze

def confirm?(message)
  response = KDK::Output.prompt("#{message} [y/N]", raise_interrupt: true)
  response.match?(/\Ay(?:es)*\z/i)
end

def execute_duo_setup
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  success = KDK::Execute::Rake.new('khulnasoft:duo:setup', env: { 'KHULNASOFT_SIMULATE_SAAS' => '1' }).execute_in_khulnasoft.success?

  KDK::Telemetry.send_custom_event(
    'ai_setup_component',
    success,
    extras: {
      component: 'duo_project',
      duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    }
  )

  success
end

def execute_dap_onboarding
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  success = KDK::Execute::Rake.new('khulnasoft:duo:onboard_dap').execute_in_khulnasoft.success?

  KDK::Telemetry.send_custom_event(
    'ai_setup_component',
    success,
    extras: {
      component: 'dap_onboarding',
      duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    }
  )

  success
end

def execute_runner_setup
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  success = KDK::Execute::Rake.new('runner:setup').execute_in_kdk.success?

  KDK::Telemetry.send_custom_event(
    'ai_setup_component',
    success,
    extras: {
      component: 'runner',
      duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)
    }
  )

  success
end

def update_env_file(env_file, key, value)
  env_contents = File.exist?(env_file) ? File.read(env_file).dup : ''
  env_contents = env_contents.strip

  if env_contents.match?(/^#{key}=/)
    env_contents.sub!(/^#{key}=.*/, "#{key}=#{value}")
  else
    env_contents << "\n" unless env_contents.empty?
    env_contents << "#{key}=#{value}"
  end

  File.write(env_file, "#{env_contents}\n")
end

desc 'Set up complete AI development environment'
task setup_ai_development: %i[setup_ai_services setup_duo_project onboard_dap setup_runner]

desc 'Set up AI Services (KhulnaSoft AI Gateway and Duo Workflow Service)'
task :setup_ai_services do
  setup_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  setup_config = {}

  KDK::Output.puts 'Setting up AI Services...'
  KDK::Telemetry.send_custom_event('ai_setup_started', true, extras: { component: 'ai_services' })

  begin
    anthropic_api_key = (ENV['ANTHROPIC_API_KEY'] ||
      KDK::Output.prompt('Enter your Anthropic API key', raise_interrupt: true)).strip
    fireworks_api_key = (ENV['FIREWORKS_API_KEY'] ||
      KDK::Output.prompt('Enter your Fireworks API key (currently shared for the team via 1Password)', raise_interrupt: true)).strip

    if anthropic_api_key.empty? || fireworks_api_key.empty?
      KDK::Output.error('API keys cannot be empty.')
      KDK::Telemetry.send_custom_event(
        'ai_setup_component',
        false,
        extras: {
          component: 'ai_services',
          error: 'empty_api_keys',
          duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
        }
      )
      next
    end

    enable_debug = if ENV['AIGW_ENABLE_DEBUG']
                     ENV['AIGW_ENABLE_DEBUG'] == 'true'
                   else
                     confirm?('Do you want to set additional environment variables for debugging?')
                   end

    setup_config[:debug_enabled] = enable_debug

    enable_hot_reload = if ENV['AIGW_ENABLE_HOT_RELOAD']
                          ENV['AIGW_ENABLE_HOT_RELOAD'] == 'true'
                        else
                          confirm?('Do you want to enable hot reload?')
                        end

    setup_config[:hot_reload_enabled] = enable_hot_reload
  rescue Interrupt
    KDK::Output.error('Setup aborted.')
    KDK::Telemetry.send_custom_event(
      'ai_setup_component',
      false,
      extras: {
        component: 'ai_services',
        error: 'user_interrupted',
        duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
      }
    )
    next
  end

  KDK::Output.puts 'Enabling AI Services in KDK config...'
  KDK.config.bury!('ai_services.enabled', true)
  KDK.config.save_yaml!

  KDK::Output.puts 'Updating KDK...'

  unless KDK::Command::Update.new.run
    KDK::Output.error('Updating KDK failed. Make sure `kdk update` runs successfully.')
    KDK::Telemetry.send_custom_event(
      'ai_setup_component',
      false,
      extras: setup_config.merge(
        component: 'ai_services',
        error: 'kdk_update_failed',
        duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
      )
    )
    next
  end

  unless File.file?(AI_GATEWAY_ENV_FILE)
    KDK::Output.error("AI Gateway env file was not found at #{AI_GATEWAY_ENV_FILE}. Run `kdk reconfigure` and try again.")
    KDK::Telemetry.send_custom_event(
      'ai_setup_component',
      false,
      extras: setup_config.merge(
        component: 'ai_services',
        error: 'env_file_missing',
        duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
      )
    )
    next
  end

  KDK::Output.puts 'Setting up Anthropic API key...'
  update_env_file(AI_GATEWAY_ENV_FILE, 'ANTHROPIC_API_KEY', anthropic_api_key)
  KDK::Output.puts 'Setting up Fireworks API key...'
  update_env_file(AI_GATEWAY_ENV_FILE, 'AIGW_MODEL_KEYS__FIREWORKS_API_KEY', fireworks_api_key)
  update_env_file(AI_GATEWAY_ENV_FILE, 'AIGW_AUTH__BYPASS_EXTERNAL', 'true')

  KDK::Output.puts 'Setting up Google Cloud...'
  sh = KDK.make('khulnasoft-ai-gateway-gcloud-setup')
  unless sh.success?
    KDK::Telemetry.send_custom_event(
      'ai_setup_component',
      false,
      extras: setup_config.merge(
        component: 'ai_services',
        error: 'gcloud_setup_failed',
        duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
      )
    )
    KDK::Output.abort("Google Cloud setup failed: #{sh.message}")
  end

  if enable_debug
    DEBUG_VARS.each { |key, value| update_env_file(AI_GATEWAY_ENV_FILE, key, value) }
    KDK::Output.puts 'Debug variables have been set.'
  end

  if enable_hot_reload
    update_env_file(AI_GATEWAY_ENV_FILE, 'AIGW_FASTAPI__RELOAD', 'true')
    KDK::Output.puts 'Hot reload has been enabled.'
  end

  KDK::Output.puts 'Restarting services...'
  KDK::Command::Restart.new.run

  KDK::Telemetry.send_custom_event(
    'ai_setup_component',
    true,
    extras: setup_config.merge(
      component: 'ai_services',
      duration_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - setup_start_time).round(2)
    )
  )

  KDK::Output.success('AI Services setup complete!')
  KDK::Output.puts "Access AI Gateway docs at the URL listed in 'kdk status'"
  KDK::Output.puts 'For more information, see https://docs.khulnasoft.com/ee/development/ai_features/index.html'
end

desc 'Configure Runner'
task :setup_runner do
  enable_runner = if ENV['ENABLE_RUNNER']
                    ENV['ENABLE_RUNNER'] == 'true'
                  else
                    confirm?('Do you want to configure Runner?')
                  end

  KDK::Telemetry.send_custom_event('ai_setup_runner_prompt', enable_runner)
  next unless enable_runner

  if execute_runner_setup
    KDK::Output.success('Runner configured successfully.')
  else
    KDK::Output.abort('Runner setup failed.')
  end
end

desc 'Create Ultimate group and project with KhulnaSoft Duo'
task :setup_duo_project do
  if execute_duo_setup
    KDK::Output.success('Created khulnasoft-duo group with test project. Go to khulnasoft-duo/test to validate Duo Chat.')
  else
    KDK::Output.abort('KhulnaSoft Duo setup failed.')
  end
end

desc 'Onboard Duo Agent Platform'
task :onboard_dap do
  if execute_dap_onboarding
    KDK::Output.success('Onboarded Duo Agent Platform successfully.')
  else
    KDK::Output.abort('Duo Agent Platform onboarding failed.')
  end
end
