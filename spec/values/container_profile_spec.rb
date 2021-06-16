# frozen_string_literal: true
require "rails_helper"

RSpec.describe ContainerProfile do
  describe "#abid_prefix" do
    it "returns the appropriate values" do
      expect(described_class.new("name" => "Object").abid_prefix(pool_identifier: "firestone")).to eq "C"
    end
    it "switches between S and B for shared box sizes in mudd/firestone" do
      expect(described_class.new("name" => "Standard manuscript").abid_prefix(pool_identifier: "firestone")).to eq "B"
      expect(described_class.new("name" => "Standard manuscript").abid_prefix(pool_identifier: "mudd")).to eq "S"
    end
    it "returns unknown for unknown pool identifiers or names" do
      expect(described_class.new("name" => "Standard manuscript").abid_prefix(pool_identifier: "dunno")).to eq "UNKNOWN"
      expect(described_class.new("name" => "dunno").abid_prefix(pool_identifier: "firestone")).to eq "UNKNOWN"
    end
  end
end
