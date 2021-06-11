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

  it "caches location_data" do
    batch = FactoryBot.create(:batch)
    batch = described_class.find(batch.id)
    client = instance_double(Aspace::Client)
    allow(batch).to receive(:aspace_client).and_return(client)

    # Ensure it uses cached data if possible.
    expect(batch.location_data).to be_present
    expect(batch.location.code).to eq "mss"
  end

  it "caches container_profile_data" do
    batch = FactoryBot.create(:batch)
    batch = described_class.find(batch.id)
    client = instance_double(Aspace::Client)
    allow(batch).to receive(:aspace_client).and_return(client)

    # Ensure it uses cached data if possible.
    expect(batch.container_profile_data).to be_present
    expect(batch.container_profile.name).to eq "Standard manuscript"
  end

  it "is invalid when requesting box numbers that don't exist" do
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 40..41)
    # The last box number in staging is 40.
    batch = FactoryBot.build(:batch, start_box: 40, end_box: 41)

    expect(batch).not_to be_valid
  end

  it "is invalid when it would request a barcode which already exists in aspace" do
    stub_barcode_search(barcodes: ["32101113342719"])
    batch = FactoryBot.build(:batch, first_barcode: "32101113342719")

    expect(batch).not_to be_valid
  end

  it "is invalid when the first barcode is invalid" do
    stub_barcode_search(barcodes: ["32101113342718"])
    batch = FactoryBot.build(:batch, first_barcode: "32101113342718")

    expect(batch).not_to be_valid
  end

  it "is invalid when another Batch exists with that barcode" do
    stub_barcode_search(barcodes: ["32101113344913"])
    stub_barcode_search(barcodes: ["32101113344905", "32101113344913"])
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..32)
    FactoryBot.create(:batch, first_barcode: "32101113344905", end_box: 32)

    batch = FactoryBot.build(:batch, first_barcode: "32101113344913")

    expect(batch).not_to be_valid
  end

  it "creates abids on save" do
    stub_barcode_search(barcodes: ["32101113344905", "32101113344913"])
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..32)
    batch = FactoryBot.create(:batch, end_box: 32)

    expect(batch.absolute_identifiers.length).to eq 2

    first_abid = batch.absolute_identifiers.first
    expect(first_abid.full_identifier).to eq "B-001556"
    expect(first_abid.barcode).to eq "32101113344905"
    second_abid = batch.absolute_identifiers.last
    expect(second_abid.full_identifier).to eq "B-001557"
    expect(second_abid.barcode).to eq "32101113344913"
  end

  it "can synchronize all member AbIDs" do
    stub_barcode_search(barcodes: ["32101113344905", "32101113344913"])
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..32)
    batch = FactoryBot.create(:batch, end_box: 32)
    stub_top_container(ref: batch.absolute_identifiers.first.top_container_uri)
    stub_top_container(ref: batch.absolute_identifiers.last.top_container_uri)
    stub_save_top_container(ref: batch.absolute_identifiers.first.top_container_uri)
    stub_save_top_container(ref: batch.absolute_identifiers.last.top_container_uri)

    expect(batch).not_to be_synchronized

    batch.synchronize

    expect(batch).to be_synchronized
  end

  it "can export attributes as CSV" do
    batch = FactoryBot.create(:batch)
    csv = CSV.parse(batch.to_csv, headers: :first_row).map(&:to_h).first
    expect(csv["id"]).not_to be_nil
    expect(csv["abid"]).to eq "B-001556"
    expect(csv["user"]).not_to be_nil
    expect(csv["barcode"]).to eq "32101113344905"
    expect(csv["location"]).to eq "Firestone Library, Vault, Manuscripts [mss]"
    expect(csv["container_profile"]).to eq "Standard manuscript"
    expect(csv["call_number"]).to eq "ABID001"
    expect(csv["box_number"]).to eq "31"
    expect(csv["status"]).to eq "unsynchronized"
  end
end
