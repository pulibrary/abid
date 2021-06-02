# frozen_string_literal: true
require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController do
  before { request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "logging in" do
    it "valid cas login redirects to home page" do
      allow(User).to receive(:from_cas) { FactoryBot.create(:user) }
      get :cas
      expect(response).to redirect_to(root_path)
      expect(flash[:success]).to eq("Successfully authenticated from from Princeton Central Authentication Service account.")
    end

    context "invalid user" do
      it "invalid cas login redirects to home page" do
        allow(User).to receive(:from_cas) { nil }
        get :cas
        expect(response).to redirect_to(root_path)
        expect(flash[:error]).to eq("You are not authorized")
      end
    end
  end
end
