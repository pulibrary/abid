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
  [:original_box_number, :prefix, :suffix, :pool_identifier, :sync_status, :top_container_uri, :batch].each do |property|
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
end
