# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Root page", type: :request do
  context "when not logged in" do
    it "displays a big button to log in" do
      get "/"

      expect(response.body).to have_link "LOGIN with NetID"
    end
  end
  context "when logged in" do
    it "redirects" do
      sign_in FactoryBot.create(:user)
      get "/"

      expect(response).to redirect_to batches_path
    end
  end
end
