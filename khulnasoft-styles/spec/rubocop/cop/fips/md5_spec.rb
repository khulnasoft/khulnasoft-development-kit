# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/fips/md5'

RSpec.describe Rubocop::Cop::Fips::MD5 do
  using RSpec::Parameterized::TableSyntax

  where(:banned_constant, :replacement) do
    'OpenSSL::Digest::MD5' | 'OpenSSL::Digest::SHA256'
    'Digest::MD5'          | 'OpenSSL::Digest::SHA256'
  end

  with_them do
    let(:message) { "MD5 is not FIPS-compliant. Use #{replacement} instead." }

    it_behaves_like 'banned constants'
  end
end
