# frozen_string_literal: true

require "rails_helper"

RSpec.describe Batch, type: :model do
  before do
    stub_resource(ead_id: "ABID001")
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    stub_location(ref: "/locations/23648")
    stub_container_profile(ref: "/container_profiles/18")
  end
  it "has a valid factory" do
    expect(FactoryBot.build(:batch)).to be_valid
  end
  it "is invalid without a call_number" do
    expect(FactoryBot.build(:batch, call_number: nil)).not_to be_valid
  end
  it "is invalid without a container_profile_uri" do
    expect(FactoryBot.build(:batch, container_profile_uri: nil)).not_to be_valid
  end
  it "is invalid without a start/end_box" do
    expect(FactoryBot.build(:batch, start_box: nil)).not_to be_valid
    expect(FactoryBot.build(:batch, end_box: nil)).not_to be_valid
    expect(FactoryBot.build(:batch, start_box: 2, end_box: 1)).not_to be_valid
  end

  it "is invalid when given a non-existent call_number" do
    stub_resource(ead_id: "nonexistent")

    bad_call_number = FactoryBot.build(:batch, call_number: "nonexistent")
    expect(bad_call_number).not_to be_valid
  end

  it "populates resource_uri as a cache when validating the first time" do
    batch = FactoryBot.build(:batch)
    batch.valid?

    expect(batch.resource_uri).to eq "/repositories/4/resources/4188"
  end

  it "is invalid when requesting box numbers that don't exist" do
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 40..41)
    # The last box number in staging is 40.
    batch = FactoryBot.build(:batch, start_box: 40, end_box: 41)

    expect(batch).not_to be_valid
  end

  it "creates abids on save" do
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..32)
    batch = FactoryBot.create(:batch, end_box: 32)

    expect(batch.absolute_identifiers.length).to eq 2

    first_abid = batch.absolute_identifiers.first
    expect(first_abid.full_identifier).to eq "B-000001"
    expect(first_abid.barcode).to eq "32101113342909"
    second_abid = batch.absolute_identifiers.last
    expect(second_abid.full_identifier).to eq "B-000002"
    expect(second_abid.barcode).to eq "32101113342917"
  end
end
