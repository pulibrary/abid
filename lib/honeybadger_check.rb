# frozen_string_literal: true

require "tzinfo"

# We have a maintenance window every Monday for Staging and Tuesday for
# production, from 5:30 AM to 8:30 AM.
class HoneybadgerCheck
  # Replaces `Time.use_zone("America/New_York")`. ActiveSupport::TimeZone was
  # only ever a wrapper over TZInfo, so the zone data and DST arithmetic here
  # are the same ones the Rails code used; only the wrapper is gone.
  ZONE = TZInfo::Timezone.get("America/New_York")

  # Stands in for `Rails.env`. `Abid.env` returns the same strings Rails' env
  # did ("staging" / "production" / ...). Kept as a class method so there is a
  # single stubbable seam, the way `Rails.env` was.
  def self.env
    Abid.env
  end

  def self.maintenance_window?
    return false unless env == "staging" || env == "production"
    # Check in Eastern time.
    current_time = ZONE.to_local(Time.now)
    # Only check times if we're the correct day of the week.
    return false if env == "staging" && !current_time.monday?
    return false if env == "production" && !current_time.tuesday?
    current_time.between?(zone_time(current_time, 5, 30), zone_time(current_time, 8, 30))
  end

  # `Time.zone.parse("5:30")` resolved to 5:30 AM on the current date in that
  # zone; reproduce that without ActiveSupport's parser.
  def self.zone_time(current_time, hour, minute)
    ZONE.local_time(current_time.year, current_time.month, current_time.day, hour, minute, 0)
  end
  private_class_method :zone_time
end
