# frozen_string_literal: true
class Location
  FIRESTONE_CODES = ["scamss", "scahsvm", "scarcpxm"].freeze
  MUDD_CODES = ["scamudd", "prnc", "scarcpph", "sc", "sls"].freeze

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

  # The pool identifier is the library where the
  # box resides.  This will not change when
  # location codes change.
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
