# frozen_string_literal: true
require "rails_helper"

RSpec.describe Aspace::Client do
  before do
    stub_aspace_login
    stub_locations
  end
  describe "#locations" do
    it "returns all locations" do
      client = described_class.new

      locations = client.locations
      expect(locations.size).to eq 26
      expect(locations[0].title).to eq "Annex, Annex B [anxb]"
    end
  end
end
