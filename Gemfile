# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: 'gem/'

gem 'openssl', '~> 3.3.1'
gem 'snowplow-tracker'

group :development do
  gem 'lefthook', '~> 2.0.1', require: false
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.6.0", require: false
  gem 'yard', '~> 0.9.37', require: false
  gem 'pry-byebug' # See doc/howto/pry.md
end

group :test do
  gem 'irb', '~> 1.15.1', require: false
  gem 'rspec', '~> 3.13.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 3.0.0', require: false
  gem 'webmock', '~> 3.25', require: false
  gem 'tzinfo'
  gem 'activesupport'
  gem 'rack'
end

group :development, :test, :danger do
  gem 'resolv', '~> 0.6.0', require: false

  gem 'ruby-lsp', "~> 0.23.0", require: false
  gem 'ruby-lsp-rspec', "~> 0.1.10", require: false
end

