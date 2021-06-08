# frozen_string_literal: true
require "rails_helper"

RSpec.describe AbsoluteIdentifier, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:absolute_identifier)).to be_valid
  end
  it "is unsynchronized by default" do
    expect(described_class.new.sync_status).to eq "unsynchronized"
  end
  it "is invalid without a batch" do
    expect(FactoryBot.build(:absolute_identifier, batch: nil)).not_to be_valid
  end
  [:original_box_number, :prefix, :pool_identifier, :sync_status, :top_container_uri, :batch, :barcode].each do |property|
    it "is invalid without #{property}" do
      expect(FactoryBot.build(:absolute_identifier, property => nil)).not_to be_valid
    end
  end

  describe "#full_identifier" do
    it "returns the combined prefix and suffix" do
      abid = FactoryBot.build(:absolute_identifier, prefix: "S", suffix: 3)
      expect(abid.full_identifier).to eq "S-000003"
    end
  end

  describe "automatically setting suffix" do
    before do
      stub_resource(ead_id: "ABID001")
      stub_location(ref: "/locations/23648")
      stub_location(ref: "/locations/23649")
      stub_container_profile(ref: "/container_profiles/18")
      stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    end
    it "sets the suffix as the next value in the pool for the given prefix before_save, using the old database's starting points" do
      mudd1 = FactoryBot.create(:mudd_batch).absolute_identifiers.first
      firestone1 = FactoryBot.create(:batch).absolute_identifiers.first
      firestone2 = FactoryBot.create(:batch).absolute_identifiers.first

      expect(mudd1.suffix).to eq 1
      expect(firestone1.suffix).to eq 1556
      expect(firestone2.suffix).to eq 1557
    end
  end

  describe "#synchronize" do
    before do
      stub_resource(ead_id: "ABID001")
      stub_location(ref: "/locations/23648")
      stub_container_profile(ref: "/container_profiles/18")
      stub_top_container(ref: "/repositories/4/top_containers/118271")
      stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    end
    it "synchronizes the identifier, location, and container profile to aspace" do
      firestone1 = FactoryBot.create(:batch).absolute_identifiers.first
      save_stub = stub_save_top_container(ref: firestone1.top_container_uri)

      firestone1.synchronize

      expect(firestone1.sync_status).to eq "synchronized"
      expect(save_stub.with(body: hash_including({ "container_profile" => { "ref" => "/container_profiles/18" } }))).to have_been_made
      expect(save_stub.with(body: hash_including(
        { "container_locations" =>
          [
            {
              "jsonmodel_type" => "container_location",
              "status" => "current",
              "ref" => "/locations/23648",
              "start_date" => Date.current.iso8601
            }
          ] }
      ))).to have_been_made
      expect(save_stub.with(body: hash_including({ "indicator" => "B-001556" }))).to have_been_made
    end
  end
end
