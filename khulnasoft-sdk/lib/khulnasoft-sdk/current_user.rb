# frozen_string_literal: true

require 'active_support'

module KhulnasoftSDK
  class CurrentUser < ::ActiveSupport::CurrentAttributes
    attribute :user_id, :user_attributes
  end
end
