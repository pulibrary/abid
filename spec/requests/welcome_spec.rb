# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Root page", type: :request do
  context "when not logged in" do
    it "displays a big button to log in" do
      get "/"

      expect(response.body).to have_link "LOGIN with NetID"
    end
  end
  context "when logged in with permission" do
    let(:user) { User.from_cas(access_token) }
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    it "redirects" do
      stub_admin_user(uid: "user", uri: "/users/1")
      sign_in user
      get "/"

      expect(response).to redirect_to batches_path
    end
  end
  context "when logged in without permission" do
    let(:user) { User.from_cas(access_token) }
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    it "displays a message" do
      stub_unauthorized_user(uid: "user", uri: "/users/1")
      sign_in user
      get "/"

      expect(response.body).to have_content "This system is only accessible by users of Princeton University Library's ArchivesSpace."
    end
  end
end
