# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'khulnasoft/styles/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.1'
  spec.name          = 'khulnasoft-styles'
  spec.version       = Khulnasoft::Styles::VERSION
  spec.authors       = ['KhulnaSoft']
  spec.email         = ['khulnasoft_rubygems@khulnasoft.com']

  spec.summary       = 'KhulnaSoft style guides and shared style configs.'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(docs|test|spec|features|playground)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rubocop', '~> 1.68.0'
  spec.add_dependency 'rubocop-capybara', '~> 2.21.0'
  spec.add_dependency 'rubocop-factory_bot', '~> 2.26.1'
  spec.add_dependency 'rubocop-graphql', '~> 1.5.4'
  spec.add_dependency 'rubocop-performance', '~> 1.21.1'
  spec.add_dependency 'rubocop-rails', '~> 2.26.0'
  spec.add_dependency 'rubocop-rspec', '~> 3.0.4'
  spec.add_dependency 'rubocop-rspec_rails', '~> 2.30.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'gitlab-dangerfiles', '~> 4.6.0'
  spec.add_development_dependency 'lefthook', '~> 1.3.13'
  spec.add_development_dependency 'pry-byebug', '~> 3.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-parameterized-table_syntax', '~> 1.0.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'simplecov-cobertura', '~> 2.1.0'
  spec.add_development_dependency 'simplecov-html', '~> 0.12.3'
  spec.add_development_dependency 'test_file_finder', '~> 0.1.4'
end
