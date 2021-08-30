# frozen_string_literal: true
require "rails_helper"

RSpec.describe MarcBatch, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:marc_batch)).to be_valid
  end
  it "can have absolute_identifiers" do
    stub_alma_barcode(barcode: "32101091123743")
    marc_batch = FactoryBot.create(:synchronized_marc_batch)
    marc_batch.reload
    expect(marc_batch.absolute_identifiers.size).to eq 1
    expect(marc_batch.absolute_identifiers.first.reload.batch).to eq marc_batch
  end

  describe "#synchronize" do
    it "calls synchronize on its abids" do
      stub_alma_barcode(barcode: "32101091123743")
      stub_alma_holding(mms_id: "9932213323506421", holding_id: "22738127790006421")
      holding_update = stub_holding_update(mms_id: "9932213323506421", holding_id: "22738127790006421")
      marc_batch = FactoryBot.create(:synchronized_marc_batch)
      marc_batch.reload

      marc_batch.synchronize

      expect(holding_update).to have_been_made
    end
  end

  it "can add absolute_identifiers with nested attributes" do
    marc_batch = FactoryBot.create(:marc_batch)
    stub_alma_barcode(barcode: "32101091123743")
    stub_alma_holding(mms_id: "9932213323506421", holding_id: "22738127790006421")
    stub_holding_update(mms_id: "9932213323506421", holding_id: "22738127790006421")
    marc_batch.absolute_identifiers_attributes = [
      {
        barcode: "32101091123743",
        prefix: "N"
      }
    ]
    marc_batch.save

    expect(marc_batch.absolute_identifiers.size).to eq 1
  end
  it "errors if you add two abids with the same holding but different sizes" do
    marc_batch = FactoryBot.build(:marc_batch)
    stub_alma_barcode(barcode: "32101091149987")
    stub_alma_barcode(barcode: "32101091149995")

    marc_batch.absolute_identifiers_attributes = [
      {
        barcode: "32101091149987",
        prefix: "N",
        pool_identifier: "firestone"
      },
      {
        barcode: "32101091149995",
        prefix: "F",
        pool_identifier: "firestone"
      }
    ]
    expect { marc_batch.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
