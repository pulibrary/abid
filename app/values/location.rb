# frozen_string_literal: true
class Location
  FIRESTONE_CODES = ["mss", "hsvm", "rcpxm"].freeze
  MUDD_CODES = ["mudd", "prnc", "rcpph", "oo", "sc", "sls"].freeze

  def self.configured_codes
    FIRESTONE_CODES + MUDD_CODES
  end

  attr_reader :code, :title, :uri, :source
  def initialize(location_hash)
    @code = location_hash["classification"]
    @title = location_hash["title"]
    @uri = location_hash["uri"]
    @source = location_hash
  end

  def pool_identifier
    if FIRESTONE_CODES.include?(code)
      "firestone"
    elsif MUDD_CODES.include?(code)
      "mudd"
    else
      "global"
    end
  end
end
