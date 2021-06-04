# frozen_string_literal: true
require "rails_helper"

RSpec.describe Aspace::Client do
  before do
    stub_aspace_login
  end
  describe "#locations" do
    it "returns all locations" do
      client = described_class.new

      locations = client.locations
      expect(locations.size).to eq 26
      expect(locations[0].title).to eq "Annex, Annex B [anxb]"
    end
  end

  describe "#container_profiles" do
    it "returns all container profiles" do
      client = described_class.new

      container_profiles = client.container_profiles
      expect(container_profiles.size).to eq 20
      expect(container_profiles[0].name).to eq "Elephant size box"
    end
  end
end
