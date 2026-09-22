# frozen_string_literal: true

require "date"

class TopContainer
  attr_reader :indicator, :uri, :source
  def initialize(hsh)
    @indicator = hsh["indicator_u_icusort"].to_i
    @uri = hsh["uri"]
    @source = hsh
  end

  def indicator=(val)
    @indicator = val
    source["indicator"] = val
  end

  def barcode=(val)
    source["barcode"] = val
  end

  def location=(ref)
    source["container_locations"] = [
      {
        "jsonmodel_type" => "container_location",
        "status" => "current",
        # The Rails app ran with Time.zone = UTC, so this was always the UTC
        # date, not the system-local one.
        "start_date" => Time.now.utc.to_date.iso8601,
        "ref" => ref
      }
    ]
  end

  def container_profile=(ref)
    source["container_profile"] = {
      "ref" => ref
    }
  end
end
