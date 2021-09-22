# frozen_string_literal: true
require "rails_helper"

RSpec.describe AbsoluteIdentifier, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:absolute_identifier)).to be_valid
  end
  it "generates abids by default" do
    expect(described_class.new.generate_abid).to eq true
  end
  it "is unsynchronized by default" do
    expect(described_class.new.sync_status).to eq "unsynchronized"
  end
  it "is invalid without a batch" do
    expect(FactoryBot.build(:absolute_identifier, batch: nil)).not_to be_valid
  end
  [:prefix, :pool_identifier, :sync_status, :batch, :barcode].each do |property|
    it "is invalid without #{property}" do
      expect(FactoryBot.build(:absolute_identifier, property => nil)).not_to be_valid
    end
  end

  context "when it's a child of a MarcBatch" do
    it "is invalid if given a barcode which is not in Alma" do
      stub_alma_barcode(barcode: "32101113344913", status: 404)
      expect(FactoryBot.build(:absolute_identifier, batch: FactoryBot.create(:marc_batch), barcode: "32101113344913")).not_to be_valid
    end
    it "is invalid if given a barcode which is not in 'rare' library" do
      stub_alma_barcode(barcode: "32101085357133")
      expect(FactoryBot.build(:absolute_identifier, batch: FactoryBot.create(:marc_batch), barcode: "32101085357133")).not_to be_valid
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
    context "when generate_abid is true" do
      it "sets the suffix as the next value in the pool for the given prefix before_save, using the old database's starting points" do
        mudd1 = FactoryBot.create(:mudd_batch).absolute_identifiers.first
        firestone1 = FactoryBot.create(:batch, first_barcode: "32101113344913").absolute_identifiers.first
        firestone2 = FactoryBot.create(:batch, first_barcode: "32101113344921").absolute_identifiers.first

        expect(mudd1.suffix).to eq 1
        expect(firestone1.suffix).to eq 1569
        expect(firestone2.suffix).to eq 1570
      end
    end
    context "when generate_abid is false" do
      it "does not set a suffix" do
        firestone1 = FactoryBot.create(:batch, generate_abid: false).absolute_identifiers.first

        expect(firestone1.suffix).to be_blank
        expect(firestone1.full_identifier).to be_blank
      end
    end
    context "generate_abid==true AFTER generate_abid==false" do
      it "does not raise an error" do
        FactoryBot.create(:batch, first_barcode: "32101113344913").absolute_identifiers.first
        FactoryBot.create(:batch, generate_abid: false).absolute_identifiers.first
        expect { FactoryBot.create(:batch, first_barcode: "32101113344921").absolute_identifiers.first }.not_to raise_error
      end
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
      expect(save_stub.with(body: hash_including({ "indicator" => "B-001569" }))).to have_been_made
      expect(save_stub.with(body: hash_including({ "barcode" => firestone1.barcode }))).to have_been_made
    end
    context "when given a a MarcBatch identifier" do
      it "synchronizes to the MARC holding" do
        stub_alma_barcode(barcode: "32101091123743")
        stub_alma_holding(mms_id: "9932213323506421", holding_id: "22738127790006421")
        holding_update = stub_holding_update(mms_id: "9932213323506421", holding_id: "22738127790006421")
        identifier = FactoryBot.create(:absolute_identifier, batch: FactoryBot.create(:marc_batch), barcode: "32101091123743", prefix: "N")

        identifier.synchronize

        expect(identifier.holding_id).to eq "22738127790006421"
        expect(identifier.holding_cache).to be_present

        expect(holding_update).to have_been_made
        expect(holding_update.with(body: including(identifier.full_identifier))).to have_been_made
        expect(holding_update.with(body: including("something"))).not_to have_been_made
      end
      it "adds an 852h if one doesn't exist already" do
        stub_alma_barcode(barcode: "32101097107245")
        # This holding was modified to have no 852h.
        stub_alma_holding(mms_id: "99104403413506421", holding_id: "22749001850006421")
        holding_update = stub_holding_update(mms_id: "99104403413506421", holding_id: "22749001850006421")
        identifier = FactoryBot.create(:absolute_identifier, batch: FactoryBot.create(:marc_batch), barcode: "32101097107245", prefix: "N")

        identifier.synchronize

        expect(holding_update).to have_been_made
        expect(holding_update.with(body: including(identifier.full_identifier))).to have_been_made
        identifier.reload
        expect(identifier.sync_status).to eq "synchronized"
      end
    end
    it "doesn't synchronize identifier if generate_abid is false" do
      firestone1 = FactoryBot.create(:batch, generate_abid: false).absolute_identifiers.first
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
      expect(save_stub.with(body: hash_including({ "indicator" => "31" }))).to have_been_made
      expect(save_stub.with(body: hash_including({ "barcode" => firestone1.barcode }))).to have_been_made
    end
  end
end
