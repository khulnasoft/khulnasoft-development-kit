# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/khulnasoft_security/system_command_injection'

RSpec.describe RuboCop::Cop::KhulnasoftSecurity::SystemCommandInjection do
  it 'does not flag correct use' do
    expect_no_offenses(<<~RUBY)
      system("/bin/ls", filename)
      exec("/bin/ls", shell_escape(filename))
    RUBY
  end

  it 'flags incorrect use' do
    expect_offense(<<~'RUBY')
      system("/bin/ls #{filename}")
      ^^^^^^ Do not include variables in the command name for system(). [...]
    RUBY
  end
end
