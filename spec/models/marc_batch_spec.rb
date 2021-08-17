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
end
