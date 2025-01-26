# frozen_string_literal: true

require_relative '../../../khulnasoft/styles/common/banned_constants'

module Rubocop
  module Cop
    module Fips
      class MD5 < RuboCop::Cop::Base
        include Khulnasoft::Styles::Common::BannedConstants

        MESSAGE_TEMPLATE = 'MD5 is not FIPS-compliant. Use %{replacement} instead.'

        REPLACEMENTS = {
          'OpenSSL::Digest::MD5' => 'OpenSSL::Digest::SHA256',
          'Digest::MD5' => 'OpenSSL::Digest::SHA256'
        }.freeze

        def initialize(config = nil, options = nil)
          @message_template = MESSAGE_TEMPLATE
          @replacements = REPLACEMENTS
          @autocorrect = false
          super
        end
      end
    end
  end
end
