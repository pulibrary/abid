# frozen_string_literal: true

require "rails_helper"

RSpec.describe Batch, type: :model do
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
    stub_aspace_login

    bad_call_number = FactoryBot.build(:batch, call_number: "nonexistent")
    expect(bad_call_number).not_to be_valid
  end
end
