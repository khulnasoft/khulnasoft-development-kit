# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/fips/open_ssl'

RSpec.describe Rubocop::Cop::Fips::OpenSSL do
  using RSpec::Parameterized::TableSyntax

  where(:banned_constant, :replacement) do
    'Digest::SHA1'         | 'OpenSSL::Digest::SHA1'
    'Digest::SHA2'         | 'OpenSSL::Digest::SHA256'
    'Digest::SHA256'       | 'OpenSSL::Digest::SHA256'
    'Digest::SHA384'       | 'OpenSSL::Digest::SHA384'
    'Digest::SHA512'       | 'OpenSSL::Digest::SHA512'
  end

  with_them do
    let(:message) { "Usage of this class is not FIPS-compliant. Use #{replacement} instead." }

    it_behaves_like 'banned constants'
  end
end
