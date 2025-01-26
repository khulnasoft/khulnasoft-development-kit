# frozen_string_literal: true

require_relative '../../../khulnasoft/styles/common/banned_constants'

module Rubocop
  module Cop
    module Fips
      class SHA1 < RuboCop::Cop::Base
        include Khulnasoft::Styles::Common::BannedConstants

        MESSAGE_TEMPLATE = 'SHA1 is likely to become non-compliant in the near future. Use %{replacement} instead.'

        REPLACEMENTS = {
          'OpenSSL::Digest::SHA1' => 'OpenSSL::Digest::SHA256',
          'Digest::SHA1' => 'OpenSSL::Digest::SHA256'
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
