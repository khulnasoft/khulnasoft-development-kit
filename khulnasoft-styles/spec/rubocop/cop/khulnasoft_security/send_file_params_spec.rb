# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/khulnasoft_security/send_file_params'

RSpec.describe RuboCop::Cop::KhulnasoftSecurity::SendFileParams do
  it 'does not flag correct use' do
    expect_no_offenses(<<~RUBY)
      basename = File.expand_path("/tmp/myproj")
      filename = File.expand_path(File.join(basename, @file.public_filename))
      raise if basename != filename
      send_file filename, disposition: 'inline'
    RUBY
  end

  it 'flags incorrect use' do
    expect_offense(<<~RUBY)
      send_file("/tmp/myproj/" + params[:filename])
      ^^^^^^^^^ Do not pass user provided params [...]
    RUBY
  end
end
