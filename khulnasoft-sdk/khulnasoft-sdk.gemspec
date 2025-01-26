# frozen_string_literal: true

require_relative "lib/khulnasoft-sdk/version"

Gem::Specification.new do |spec|
  spec.name = "khulnasoft-sdk"
  spec.version = KhulnasoftSDK::VERSION
  spec.authors = ["KhulnaSoft"]
  spec.email = ["khulnasoft_rubygems@khulnasoft.com"]

  spec.summary = "Client side Ruby SDK for KhulnaSoft Application services"
  spec.description = "Client side Ruby SDK for KhulnaSoft Application services"
  spec.homepage = "https://github.com/khulnasoft/khulnasoft-development-kit/tree/main/khulnasoft-sdk"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/khulnasoft/khulnasoft-development-kit/tree/main/khulnasoft-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/khulnasoft/khulnasoft-development-kit/tree/main/khulnasoft-sdk/-/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.2.0"
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "snowplow-tracker", "~> 0.8.0"

  spec.add_development_dependency "khulnasoft-styles", "~> 10.0.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"
end
