# frozen_string_literal: true
require "rails_helper"

RSpec.describe BatchesController do
  before do
    stub_aspace_login
  end
  context "when logged in as an admin" do
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    before do
      stub_admin_user(uid: "user", uri: "/users/1")
      user = User.from_cas(access_token)
      sign_in user
    end

    it "displays a form for creating a new batch on the index page" do
      get "/batches"

      expect(response.body).to have_field "Call number"
      expect(response.body).to have_field "First barcode"
      expect(response.body).to have_field "Start box"
      expect(response.body).to have_field "End box"

      expect(response.body).to have_select "Container profile", with_options: ["Elephant size box"]
      # Ensure locations are filtered to just the configured ones.
      expect(response.body).not_to have_select "Location", with_options: ["Annex, Annex B [anxb]"]
      expect(response.body).to have_select "Location", with_options: ["Firestone Library, Vault, Manuscripts [mss]"]
      expect(response.body).to have_checked_field "Generate Absolute Identifier"
    end
  end
  context "when not logged in" do
    it "redirects to the root" do
      get "/batches"

      expect(response).to redirect_to root_path
    end
  end
  context "when logged in as a non-staff user" do
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    before do
      stub_unauthorized_user(uid: "user", uri: "/users/1")
      user = User.from_cas(access_token)
      sign_in user
    end
    it "redirects to the root" do
      get "/batches"

      expect(response).to redirect_to root_path
    end
  end
end
