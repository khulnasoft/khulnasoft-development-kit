# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/fips/sha1'

RSpec.describe Rubocop::Cop::Fips::SHA1 do
  using RSpec::Parameterized::TableSyntax

  where(:banned_constant, :replacement) do
    'OpenSSL::Digest::SHA1' | 'OpenSSL::Digest::SHA256'
    'Digest::SHA1'          | 'OpenSSL::Digest::SHA256'
  end

  with_them do
    let(:message) { "SHA1 is likely to become non-compliant in the near future. Use #{replacement} instead." }

    it_behaves_like 'banned constants'
  end
end
