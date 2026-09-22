# frozen_string_literal: true

# Rails defaulted `config.time_zone` to "UTC", and this app never overrode it,
# so `Date.current` meant "today in UTC" both in the application and in the
# specs that assert on it (spec/models/absolute_identifier_spec.rb compares
# TopContainer's container_location start_date against `Date.current.iso8601`).
#
# The ported TopContainer uses `Time.now.utc.to_date`, which preserves that.
# ActiveSupport is still present in the bundle (a transitive dependency of the
# `alma` gem) so the specs' `Date.current` still resolves, but with no Time.zone
# set it silently falls back to the LOCAL date. The two agree for most of the
# day and diverge between 17:00 US/Pacific and 00:00 UTC, which made these
# specs fail only in the evening.
#
# Setting the zone here restores Rails' default for the test harness only; no
# application code depends on ActiveSupport.
Time.zone = "UTC" if Time.respond_to?(:zone=)
