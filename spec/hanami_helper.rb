# frozen_string_literal: true

# Entry point required by every spec file. Replaces the Rails app's
# spec/rails_helper.rb; nothing Rails is loaded here.
require "spec_helper"

ENV["HANAMI_ENV"] = "test"

require "hanami/boot"
require "rack/test"
require "capybara/rspec"
require "factory_bot"
require "webmock/rspec"
# Rails auto-required gems via Bundler.require; Hanami does not.
require "shellwords"
require "timecop"
require "omniauth"

# Domain code lives in lib/, which is on the load path but is not
# Zeitwerk-managed for top-level constants, so require it explicitly.
require "application_record"
%w[
  barcode_service container_profile location top_container
  aspace/client synchronizer synchronizer/marc_synchronizer honeybadger_check
  git_version vite_tags
  user batch marc_batch absolute_identifier
].each { |file| require file }

Dir[Abid::APP_ROOT.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

FactoryBot.definition_file_paths = [Abid::APP_ROOT.join("spec", "factories")]
FactoryBot.find_definitions

# Deleted in dependency order; absolute_identifiers.batch_id has no foreign
# key, but batches/marc_batches do reference users.
TABLES_IN_DELETE_ORDER = %i[absolute_identifiers batches marc_batches users].freeze

def truncate_tables
  connection = Hanami.app["db.gateway"].connection
  TABLES_IN_DELETE_ORDER.each { |table| connection[table].delete }
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Replaces rspec-rails' infer_spec_type_from_file_location!, which the Rails
  # spec_helper called. Keeps `type:` implicit so no spec file needs a tag.
  config.define_derived_metadata(file_path: %r{/spec/requests/}) { |m| m[:type] ||= :request }
  config.define_derived_metadata(file_path: %r{/spec/controllers/}) { |m| m[:type] ||= :request }
  config.define_derived_metadata(file_path: %r{/spec/system/}) { |m| m[:type] ||= :system }
  config.define_derived_metadata(file_path: %r{/spec/models/}) { |m| m[:type] ||= :model }

  # Leave no rows behind from a previous interrupted run.
  config.before(:suite) { truncate_tables }

  # Replaces `use_transactional_fixtures`: every example runs inside a
  # transaction that is rolled back, so examples never see each other's rows.
  config.around(:each) do |example|
    if example.metadata[:type] == :system
      # System specs are served by a real Puma server on its own database
      # connection, so a transaction opened here would not wrap the rows the
      # server writes (and the server could not see rows written here).
      # Truncate instead, which is what use_transactional_fixtures' shared
      # connection made unnecessary under Rails.
      begin
        example.run
      ensure
        truncate_tables
      end
    else
      Hanami.app["db.gateway"].connection.transaction(rollback: :always, auto_savepoint: true) do
        example.run
      end
    end
  end
end
