# frozen_string_literal: true

require "hanami_helper"

# Regression coverage for CAS login. The original suite only ever signed in
# through a helper that built the auth hash from a User record, so `provider`
# was always a String out of the database. The real OmniAuth strategy names the
# provider with a Symbol, which reached Sequel as a column identifier and made
# every real login fail with
# `PG::UndefinedColumn: column "cas" does not exist`.
RSpec.describe "CAS login", type: :request do
  let(:symbol_auth_hash) do
    OmniAuth::AuthHash.new(provider: :cas, uid: "netid123")
  end

  before do
    OmniAuth.config.mock_auth[:cas] = symbol_auth_hash
  end

  context "when the provider is a Symbol, as the real strategy supplies it" do
    it "creates the user and signs them in" do
      stub_unauthorized_user(uid: "netid123", uri: "/users/1")

      get "/users/auth/cas/callback"

      expect(response).to redirect_to root_path
      expect(User.find_by(uid: "netid123")).not_to be_nil
    end

    it "finds an existing user rather than raising" do
      stub_unauthorized_user(uid: "netid123", uri: "/users/1")
      FactoryBot.create(:user, uid: "netid123", provider: "cas")

      expect { get "/users/auth/cas/callback" }.not_to raise_error
      expect(response).to redirect_to root_path
      expect(User.where(uid: "netid123").count).to eq 1
    end
  end
end
