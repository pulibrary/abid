# frozen_string_literal: true
require "rails_helper"

RSpec.describe MarcBatch, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:marc_batch)).to be_valid
  end
  it "can have absolute_identifiers" do
    marc_batch = FactoryBot.create(:marc_batch, absolute_identifiers: [FactoryBot.build(:absolute_identifier)])
    expect(marc_batch.absolute_identifiers.size).to eq 1
    expect(marc_batch.absolute_identifiers.first.reload.batch).to eq marc_batch
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
