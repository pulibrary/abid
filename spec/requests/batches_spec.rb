# frozen_string_literal: true
require "rails_helper"

RSpec.describe BatchesController do
  before do
    stub_aspace_login
  end

  describe "#destroy" do
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    before do
      stub_admin_user(uid: "user", uri: "/users/1")
      user = User.from_cas(access_token)
      stub_resource(ead_id: "ABID001")
      stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
      stub_location(ref: "/locations/23648")
      stub_container_profile(ref: "/container_profiles/18")
      stub_top_container(ref: "/repositories/4/top_containers/118271")
      sign_in user
    end

    context "when a batch is synchronized" do
      it "does not destroy it" do
        batch = FactoryBot.create(:synchronized_batch)

        delete "/batches/#{batch.id}"

        expect { Batch.find(batch.id) }.not_to raise_error
        expect(flash.alert).to eq "Unable to delete synchronized Batches."
      end
    end
    context "when a batch is not synchronized" do
      it "destroys it" do
        batch = FactoryBot.create(:batch)

        delete "/batches/#{batch.id}"

        expect { Batch.find(batch.id) }.to raise_error ActiveRecord::RecordNotFound
        expect(AbsoluteIdentifier.all.size).to eq 0
      end
    end
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
      expect(response.body).to have_select "Location", with_options: ["Annex, Annex B [anxb]"]
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
