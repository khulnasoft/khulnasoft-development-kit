# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/rspec/verbose_include_metadata'

RSpec.describe Rubocop::Cop::RSpec::VerboseIncludeMetadata do
  shared_examples 'examples with include syntax' do |title|
    it "flags violation for #{title} examples that uses verbose include syntax" do
      offensive_source = <<-RUBY.sub('TITLE', title).sub('^', '^' * (title.size + 17))
        TITLE 'Test', js: true do
        ^ Use `:js` instead of `js: true`.
        end
      RUBY

      expect_offense(offensive_source)

      offense_correction = <<-RUBY.sub('TITLE', title)
        TITLE 'Test', :js do
        end
      RUBY

      expect_correction(offense_correction)
    end

    it "doesn't flag violation for #{title} examples that uses compact include syntax", :aggregate_failures do
      expect_no_offenses("#{title} 'Test', :js do; end")
    end

    it "doesn't flag violation for #{title} examples that uses flag: symbol" do
      expect_no_offenses("#{title} 'Test', flag: :symbol do; end")
    end

    it "autocorrects #{title} examples that uses verbose syntax into compact syntax" do
      offensive_source = <<-RUBY.sub('TITLE', title).sub('^', '^' * (title.size + 17))
        TITLE 'Test', js: true do; end
        ^ Use `:js` instead of `js: true`.
      RUBY

      expect_offense(offensive_source)

      offense_correction = <<-RUBY.sub('TITLE', title)
        TITLE 'Test', :js do; end
      RUBY

      expect_correction(offense_correction)
    end
  end

  %w[describe context feature example_group it specify example scenario its].each do |example|
    it_behaves_like 'examples with include syntax', example
  end
end
