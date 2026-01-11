# frozen_string_literal: true

RSpec.describe 'rake setup_ai_development', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/setup_ai_development')
  end

  it 'runs setup_ai_services, setup_duo_project, onboard_dap, and setup_runner as prerequisites' do
    expect(Rake::Task['setup_ai_development'].prerequisites).to eq(%w[setup_ai_services setup_duo_project onboard_dap setup_runner])
  end
end

RSpec.describe 'rake setup_ai_services', :hide_output do
  include ShelloutHelper

  let(:env_file) { AI_GATEWAY_ENV_FILE }
  let(:log_file) { LOG_FILE }
  let(:gateway_enabled) { false }
  let(:raw_yaml) do
    "---\nai_services:\n  enabled: #{gateway_enabled}\nkdk:\n  root: /path/to/kdk"
  end

  before(:all) do
    Rake.application.rake_require('tasks/setup_ai_development')
  end

  before do
    stub_raw_kdk_yaml(raw_yaml)
    allow(KDK::Output).to receive(:prompt).and_return('test_input')
    allow(File).to receive_messages(write: nil, exist?: false, read: '', open: nil)
    allow(File).to receive(:file?).with(env_file.to_s).and_return(true)
    allow(KDK.config).to receive(:bury!).with('ai_services.enabled', true)
    allow(KDK.config).to receive(:save_yaml!)
    allow_any_instance_of(KDK::Command::Update).to receive(:run).and_return(true)
    allow_any_instance_of(KDK::Command::Restart).to receive(:run)
    allow(KDK).to receive(:make).with('khulnasoft-ai-gateway-gcloud-setup').and_return(kdk_shellout_double(success?: true))
    stub_env('ANTHROPIC_API_KEY', nil)
    stub_env('FIREWORKS_API_KEY', nil)
    stub_env('AIGW_ENABLE_DEBUG', nil)
    stub_env('AIGW_ENABLE_HOT_RELOAD', nil)
  end

  context 'when running the task' do
    before do
      allow(KDK::Output).to receive(:prompt).with(
        'Enter your Anthropic API key',
        raise_interrupt: true
      ).and_return('test_api_key')
      allow(KDK::Output).to receive(:prompt)
        .with('Do you want to set additional environment variables for debugging? [y/N]', raise_interrupt: true)
        .and_return('y')
      allow(KDK::Output).to receive(:prompt)
        .with('Do you want to enable hot reload? [y/N]', raise_interrupt: true)
        .and_return('y')
      allow(File).to receive(:exist?).with(env_file.to_s).and_return(false)
    end

    it 'configures AI Services, updates environment, and restarts services' do
      expect(KDK.config).to receive(:bury!).with('ai_services.enabled', true)
      expect(KDK.config).to receive(:save_yaml!)
      expect(File).to receive(:write).with(env_file.to_s, "ANTHROPIC_API_KEY=test_api_key\n").ordered
      expect(KDK).to receive(:make).with('khulnasoft-ai-gateway-gcloud-setup').and_return(
        kdk_shellout_double(success?: true)
      )
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__LEVEL=debug\n")
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__FORMAT_JSON=false\n")
      expect(File).to receive(:write).with(
        env_file.to_s,
        %r{AIGW_LOGGING__TO_FILE=.*/log/khulnasoft-ai-gateway/gateway_debug\.log\n}
      )
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_FASTAPI__RELOAD=true\n")

      task.execute
    end
  end

  context 'when required prompts are provided as environment variables' do
    it 'uses provided API keys without prompting user' do
      stub_env('ANTHROPIC_API_KEY', 'test_anthropic')
      stub_env('FIREWORKS_API_KEY', 'test_fireworks')
      stub_env('AIGW_ENABLE_DEBUG', 'false')
      stub_env('AIGW_ENABLE_HOT_RELOAD', 'false')

      expect(KDK::Output).not_to receive(:prompt)
      expect(KDK.config).to receive(:bury!).with('ai_services.enabled', true)
      expect(KDK.config).to receive(:save_yaml!)
      expect(File).to receive(:write).with(env_file.to_s, "ANTHROPIC_API_KEY=test_anthropic\n")
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_MODEL_KEYS__FIREWORKS_API_KEY=test_fireworks\n")

      task.execute
    end

    context 'when AIGW_ENABLE_DEBUG environment variable is true' do
      it 'enables debug mode' do
        stub_env('ANTHROPIC_API_KEY', 'test_anthropic')
        stub_env('FIREWORKS_API_KEY', 'test_fireworks')
        stub_env('AIGW_ENABLE_DEBUG', 'true')
        stub_env('AIGW_ENABLE_HOT_RELOAD', 'false')

        expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__LEVEL=debug\n")
        expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__FORMAT_JSON=false\n")
        expect(File).to receive(:write).with(
          env_file.to_s,
          %r{AIGW_LOGGING__TO_FILE=.*/log/khulnasoft-ai-gateway/gateway_debug\.log\n}
        )

        task.execute
      end
    end

    context 'when AIGW_ENABLE_HOT_RELOAD environment variable is true' do
      it 'enables hot reload' do
        stub_env('ANTHROPIC_API_KEY', 'test_anthropic')
        stub_env('FIREWORKS_API_KEY', 'test_fireworks')
        stub_env('AIGW_ENABLE_DEBUG', 'false')
        stub_env('AIGW_ENABLE_HOT_RELOAD', 'true')

        expect(File).to receive(:write).with(env_file.to_s, "AIGW_FASTAPI__RELOAD=true\n")

        task.execute
      end
    end

    context 'when only some environment variables are provided' do
      it 'falls back to interactive mode for missing values' do
        stub_env('FIREWORKS_API_KEY', 'test_fireworks')

        expect(KDK::Output).to receive(:prompt).with(
          'Enter your Anthropic API key',
          raise_interrupt: true
        ).and_return('prompted_anthropic_key')
        expect(KDK::Output).to receive(:prompt).with(
          /Do you want to set additional environment variables for debugging?/,
          raise_interrupt: true
        ).and_return('n')
        expect(KDK::Output).to receive(:prompt).with(
          'Do you want to enable hot reload? [y/N]',
          raise_interrupt: true
        ).and_return('n')

        task.execute
      end
    end
  end

  context 'when user declines debug variables and hot reload' do
    let(:gateway_enabled) { true }

    before do
      allow(KDK::Output).to receive(:prompt).with(
        'Enter your Anthropic API key',
        raise_interrupt: true
      ).and_return('test_api_key')
      allow(KDK::Output).to receive(:prompt).with(
        /Do you want to set additional environment variables for debugging?/,
        raise_interrupt: true
      ).and_return('n')
      allow(KDK::Output).to receive(:prompt).with(
        'Do you want to enable hot reload? [y/N]',
        raise_interrupt: true
      ).and_return('n')
    end

    it 'skips setting debug variables and enabling hot reload' do
      expect(File).not_to receive(:write).with(env_file.to_s, /AIGW_LOGGING__LEVEL=debug/)
      expect(File).not_to receive(:write).with(env_file.to_s, /AIGW_FASTAPI__RELOAD=true/)

      task.execute
    end
  end

  context 'when .env file already exists' do
    let(:existing_env_content) { "EXISTING_VAR=value\n" }
    let(:gateway_enabled) { true }

    before do
      allow(File).to receive(:exist?).with(env_file.to_s).and_return(true)
      allow(File).to receive(:read).with(env_file.to_s).and_return(existing_env_content)
      allow(KDK::Output).to receive(:prompt).with(
        'Enter your Anthropic API key',
        raise_interrupt: true
      ).and_return('test_anthropic_api_key')
      allow(KDK::Output).to receive(:prompt).with(
        'Enter your Fireworks API key (currently shared for the team via 1Password)',
        raise_interrupt: true
      ).and_return('test_fireworks_api_key')
    end

    it 'updates existing ANTHROPIC_API_KEY if present' do
      allow(File).to receive(:read).with(env_file.to_s).and_return("ANTHROPIC_API_KEY=old_key\n")
      expect(File).to receive(:write).with(env_file.to_s, "ANTHROPIC_API_KEY=test_anthropic_api_key\n")

      task.execute
    end

    it 'appends ANTHROPIC_API_KEY if not present' do
      expect(File).to receive(:write).with(
        env_file.to_s,
        "EXISTING_VAR=value\nANTHROPIC_API_KEY=test_anthropic_api_key\n"
      )

      task.execute
    end

    it 'updates existing AIGW_MODEL_KEYS__FIREWORKS_API_KEY if present' do
      allow(File).to receive(:read).with(env_file.to_s).and_return("AIGW_MODEL_KEYS__FIREWORKS_API_KEY=old_key\n")
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_MODEL_KEYS__FIREWORKS_API_KEY=test_fireworks_api_key\n")

      task.execute
    end

    it 'appends AIGW_MODEL_KEYS__FIREWORKS_API_KEY if not present' do
      expect(File).to receive(:write).with(
        env_file.to_s,
        "EXISTING_VAR=value\nAIGW_MODEL_KEYS__FIREWORKS_API_KEY=test_fireworks_api_key\n"
      )

      task.execute
    end

    it 'handles frozen strings correctly' do
      frozen_content = "EXISTING_VAR=value\n"
      allow(File).to receive(:read).with(env_file.to_s).and_return(frozen_content)
      expect(File).to receive(:write).with(
        env_file.to_s,
        "EXISTING_VAR=value\nANTHROPIC_API_KEY=test_anthropic_api_key\n"
      )
      expect(File).to receive(:write).with(
        env_file.to_s,
        "EXISTING_VAR=value\nAIGW_MODEL_KEYS__FIREWORKS_API_KEY=test_fireworks_api_key\n"
      )

      expect { task.execute }.not_to raise_error
    end
  end
end

RSpec.describe 'rake setup_duo_project', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/setup_ai_development')
  end

  before do
    allow(KDK::Execute::Rake).to receive(:new).and_return(
      instance_double(KDK::Execute::Rake, execute_in_khulnasoft: instance_double(KDK::Execute::Rake, success?: true))
    )
  end

  it 'executes khulnasoft:duo:setup with correct environment' do
    expect(KDK::Execute::Rake).to receive(:new).with('khulnasoft:duo:setup', env: { 'KHULNASOFT_SIMULATE_SAAS' => '1' }).and_return(instance_double(KDK::Execute::Rake, execute_in_khulnasoft: instance_double(KDK::Execute::Rake, success?: true)))

    Rake::Task['setup_duo_project'].execute
  end
end

RSpec.describe 'rake setup_runner', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/setup_ai_development')
  end

  before do
    allow(KDK::Execute::Rake).to receive(:new).and_return(
      instance_double(KDK::Execute::Rake, execute_in_kdk: instance_double(KDK::Execute::Rake, success?: true))
    )
    allow(KDK::Output).to receive(:prompt).and_return('y')
    stub_env('ENABLE_RUNNER', nil)
  end

  context 'when ENABLE_RUNNER is true' do
    it 'executes runner:setup without prompting' do
      stub_env('ENABLE_RUNNER', 'true')

      expect(KDK::Output).not_to receive(:prompt)
      expect(KDK::Execute::Rake).to receive(:new).with('runner:setup').and_return(instance_double(KDK::Execute::Rake, execute_in_kdk: instance_double(KDK::Execute::Rake, success?: true)))

      Rake::Task['setup_runner'].execute
    end
  end

  context 'when ENABLE_RUNNER is not set' do
    it 'prompts user and executes runner:setup if confirmed' do
      expect(KDK::Output).to receive(:prompt).with('Do you want to configure Runner? [y/N]', raise_interrupt: true).and_return('y')

      Rake::Task['setup_runner'].execute
    end
  end
end
