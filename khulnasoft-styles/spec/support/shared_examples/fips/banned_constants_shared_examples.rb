# frozen_string_literal: true

# Shared examples for cops which use Khulnasoft::Styles::Common::BannedConstants
# as a superclass.
#
# Requires the following variables to be defined in the spec:
#
# cop: The subject (described_class.new)
# banned_constant: The constant name which should be flagged by the cop
# replacement: The new constant that it should be replaced with
# message: The error message which the cop should output

RSpec.shared_examples 'banned constants' do
  it 'flags digest initialization' do
    expect_offense(<<~RUBY, banned_constant: banned_constant)
    def digest
      %{banned_constant}.new
      ^{banned_constant} #{message}
    end
    RUBY

    expect_correction(<<~RUBY) if cop.autocorrect
    def digest
      #{replacement}.new
    end
    RUBY
  end

  it 'flags hexdigest usage' do
    expect_offense(<<~RUBY, banned_constant: banned_constant)
    %{banned_constant}.hexdigest('The quick brown fox jumped over the lazy dog')
    ^{banned_constant} #{message}
    RUBY

    expect_correction(<<~RUBY) if cop.autocorrect
    #{replacement}.hexdigest('The quick brown fox jumped over the lazy dog')
    RUBY
  end

  it 'flags :: prefixes' do
    expect_offense(<<~RUBY, banned_constant: banned_constant)
    def digest
      ::%{banned_constant}.new
      ^^^{banned_constant} #{message}
    end
    RUBY

    expect_correction(<<~RUBY) if cop.autocorrect
    def digest
      ::#{replacement}.new
    end
    RUBY
  end

  it 'flags aliased class names' do
    expect_offense(<<~RUBY, banned_constant: banned_constant)
    DIGEST_CLASS = %{banned_constant}
                   ^{banned_constant} #{message}
    DIGEST_CLASS.new
    RUBY

    expect_correction(<<~RUBY) if cop.autocorrect
    DIGEST_CLASS = #{replacement}
    DIGEST_CLASS.new
    RUBY
  end

  context 'when constant is prefixed with a non-constant' do
    let(:source) do
      <<~SOURCE
      if Khulnasoft::CurrentSettings.admin_mode
        return admin_mode_flow(auth_module::User) if current_user_mode.admin_mode_requested?
      end
      SOURCE
    end

    it 'does not error' do
      expect_no_offenses(source)
    end
  end
end
