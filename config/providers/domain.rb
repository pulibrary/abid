# frozen_string_literal: true

# Rails eager-loaded these from app/models, app/services and app/values. lib/
# is on $LOAD_PATH but is deliberately not Zeitwerk-managed, so the top-level
# domain constants have to be required explicitly to be available app-wide.
#
# Order matters: lib/synchronizer/marc_synchronizer.rb reopens `class
# Synchronizer` to nest MarcSynchronizer inside it, so the base class is
# required first. (marc_synchronizer.rb also requires it itself, so the order
# here is belt and braces.)
#
# Hanami loads provider files lazily, so this runs on `Hanami.app.boot`. In a
# prepare-only process (`require "hanami/prepare"`) call
# `Hanami.app.start(:domain)` to force it.
Hanami.app.register_provider(:domain) do
  prepare do
    require "barcode_service"
    require "container_profile"
    require "location"
    require "top_container"
    require "aspace/client"
    require "aspace/client_factory"
    require "synchronizer"
    require "synchronizer/marc_synchronizer"
    require "honeybadger_check"

    # The models. These were missing, so a `hanami server` boot raised
    # `uninitialized constant User` on the first request; only
    # spec/rails_helper.rb required them, which hid it from the suite.
    # spec/boot_spec.rb now boots a clean subprocess to keep it visible.
    require "application_record"
    require "user"
    require "batch"
    require "marc_batch"
    require "absolute_identifier"
  end
end
