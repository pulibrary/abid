# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }

  describe "#from_cas" do
    context "and there's a user with that netid in aspace" do
      it "pulls the URI into the user and creates it" do
        stub_unauthorized_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)
        expect(user.aspace_uri).to eq "/users/1"
      end
    end
    context "when a user already exists" do
      before do
        FactoryBot.create(:user, uid: "user", provider: "cas")
      end
      it "returns a user object and updates it with the missing URI" do
        stub_unauthorized_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)
        expect(user).to be_a described_class
        expect(user.aspace_uri).to eq "/users/1"
      end
    end
  end
end
