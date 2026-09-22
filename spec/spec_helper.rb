# frozen_string_literal: true

require "simplecov"

# The Rails app used SimpleCov's built-in "rails" profile. That profile is part
# of the Rails ecosystem and assumes Rails' directory layout, so the equivalent
# filters are spelled out here instead.
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/node_modules/"

  add_group "Actions", "app/actions"
  add_group "Views", "app/views"
  add_group "Relations", "app/relations"
  add_group "Models", ["lib/batch.rb", "lib/marc_batch.rb", "lib/absolute_identifier.rb", "lib/user.rb"]
  add_group "Services", ["lib/aspace", "lib/synchronizer", "lib/barcode_service.rb"]
  add_group "Values", ["lib/container_profile.rb", "lib/location.rb", "lib/top_container.rb"]
end

ENV["HANAMI_ENV"] ||= "test"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
end
