# frozen_string_literal: true

require_relative '../../../khulnasoft/styles/common/banned_constants'

module Rubocop
  module Cop
    module Fips
      class OpenSSL < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector
        include Khulnasoft::Styles::Common::BannedConstants

        MESSAGE_TEMPLATE = 'Usage of this class is not FIPS-compliant. Use %{replacement} instead.'

        REPLACEMENTS = {
          'Digest::SHA1' => 'OpenSSL::Digest::SHA1',
          'Digest::SHA2' => 'OpenSSL::Digest::SHA256',
          'Digest::SHA256' => 'OpenSSL::Digest::SHA256',
          'Digest::SHA384' => 'OpenSSL::Digest::SHA384',
          'Digest::SHA512' => 'OpenSSL::Digest::SHA512'
        }.freeze

        def initialize(config = nil, options = nil)
          @message_template = MESSAGE_TEMPLATE
          @replacements = REPLACEMENTS
          @autocorrect = true
          super
        end
      end
    end
  end
end
