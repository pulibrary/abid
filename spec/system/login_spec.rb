# frozen_string_literal: true
require "rails_helper"

RSpec.describe "login workflow" do
  before do
    OmniAuth.config.test_mode = true
  end
  # The return cookie gets lost if we don't set app_host for some reason?
  around do |example|
    old_host = Capybara.app_host
    Capybara.app_host = "http://localhost:3000"
    example.call
    Capybara.app_host = old_host
  end
  context "when logging in as an aspace admin" do
    before do
      stub_admin_user(uid: "admin123", uri: "/users/1")
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new({
                                                                            "provider" => :openid_connect,
                                                                            "uid" => "admin123@princeton.edu",
                                                                            "info" => {},
                                                                            "credentials" => {
                                                                              "id_token" => "secret",
                                                                              "token" => "secret",
                                                                              "refresh_token" => nil,
                                                                              "expires_in" => 4489,
                                                                              "scope" => "email openid profile"
                                                                            },
                                                                            "extra" => {
                                                                              "raw_info" => {
                                                                                "sub" => "",
                                                                                "preferred_username" => "admin123@princeton.edu"
                                                                              }
                                                                            }
                                                                          })
    end
    it "logs in from the home page and goes to batches" do
      visit "/"
      click_button "LOGIN with NetID"
      expect(page).to have_button "Create Batch"
      expect(page.current_path).to eq "/batches"
      expect(User.last.uid).to eq "admin123"
    end
    it "logs in from the sign in page" do
      visit "/sign_in"
      click_button "Log in with Princeton Net ID"
      expect(page.current_path).to eq "/batches"
    end
  end
  context "when sending an invalid auth" do
    before do
      OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
    end
    it "errors" do
      visit "/"
      click_button "LOGIN with NetID"
      expect(page).to have_content "Invalid credentials"
      expect(page.current_path).to eq "/sign_in"
    end
  end
end
