# frozen_string_literal: true

# Auto-require all cops under `rubocop/cop/**/*.rb`
cops_glob = File.join(__dir__, '..', '..', 'rubocop', 'cop', '**', '*.rb')
Dir[cops_glob].each { |cop| require(cop) }

module Khulnasoft
  module Styles
    module Rubocop
    end
  end
end
