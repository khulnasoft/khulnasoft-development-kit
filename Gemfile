# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: 'gem/'

group :development do
  gem 'khulnasoft-styles', path: 'khulnasoft-styles', require: false
  gem 'khulnasoft-sdk', path: 'khulnasoft-sdk'
  gem 'lefthook', '~> 1.10.3', require: false
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.6.0", require: false
  gem 'yard', '~> 0.9.37', require: false
  gem 'pry-byebug' # See doc/howto/pry.md
end

group :test do
  gem 'irb', '~> 1.14.3', require: false
  gem 'rspec', '~> 3.13.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
  gem 'webmock', '~> 3.24', require: false
end

group :development, :test, :danger do
  gem 'gitlab-dangerfiles', '~> 4.8.1', require: false
  gem 'resolv', '~> 0.6.0', require: false
end
