# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }

  before do
    FactoryBot.create(:user, uid: "user", provider: "cas")
  end

  describe "#from_cas" do
    it "returns a user object" do
      expect(described_class.from_cas(access_token)).to be_a described_class
    end
  end
end
