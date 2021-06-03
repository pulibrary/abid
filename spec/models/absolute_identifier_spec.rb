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
      stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    end
    it "sets the suffix as the next value in the pool for the given prefix before_save" do
      mudd1 = FactoryBot.create(:absolute_identifier, prefix: "S", pool_identifier: "mudd")
      firestone1 = FactoryBot.create(:absolute_identifier, prefix: "S", pool_identifier: "firestone")
      firestone2 = FactoryBot.create(:absolute_identifier, prefix: "S", pool_identifier: "firestone")

      expect(mudd1.suffix).to eq 1
      expect(firestone1.suffix).to eq 1
      expect(firestone2.suffix).to eq 2
    end
  end
end
