# frozen_string_literal: true
require "rails_helper"

RSpec.describe MarcBatch, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:marc_batch)).to be_valid
  end
  it "can have absolute_identifiers" do
    stub_alma_barcode(barcode: "32101091123743")
    marc_batch = FactoryBot.create(:synchronized_marc_batch)
    expect(marc_batch.absolute_identifiers.size).to eq 1
    expect(marc_batch.absolute_identifiers.first.reload.batch).to eq marc_batch
  end

  describe "#synchronize" do
    it "calls synchronize on its abids" do
      stub_alma_barcode(barcode: "32101091123743")
      stub_alma_holding(mms_id: "9932213323506421", holding_id: "22738127790006421")
      holding_update = stub_holding_update(mms_id: "9932213323506421", holding_id: "22738127790006421")
      marc_batch = FactoryBot.create(:synchronized_marc_batch)
      allow(marc_batch.absolute_identifiers.first).to receive(:synchronize)

      marc_batch.synchronize

      expect(holding_update).to have_been_made
    end
  end

  it "can add absolute_identifiers with nested attributes" do
    marc_batch = FactoryBot.create(:marc_batch)
    marc_batch.absolute_identifiers_attributes = [
      {
        barcode: "32101091126100",
        prefix: "N"
      },
      {
        barcode: "32101091126290",
        prefix: "N"
      },
      {
        barcode: "32101094767611",
        prefix: "Q"
      }
    ]
    marc_batch.save

    expect(marc_batch.absolute_identifiers.size).to eq 3
  end
end
