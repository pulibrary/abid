# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Batch management" do
  before do
    stub_resource(ead_id: "ABID001")
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    stub_location(ref: "/locations/23648")
    stub_container_profile(ref: "/container_profiles/18")
    stub_top_container(ref: "/repositories/4/top_containers/118271")
    stub_save_top_container(ref: "/repositories/4/top_containers/118271")
    sign_in FactoryBot.create(:user)
  end
  it "can create and synchronize a batch" do
    visit "/"
    fill_in "First barcode", with: "32101113342909"
    fill_in "Call number", with: "ABID001"
    fill_in "Start box", with: 31
    fill_in "End box", with: 31
    select "Firestone Library, Vault, Manuscripts [mss]", from: "Location"
    select "Standard manuscript", from: "Container profile"
    click_button "Create Batch"

    batch = Batch.first
    expect(batch.absolute_identifiers.size).to eq 1

    within("#unsynchronized-batches") do
      expect(page).to have_content "B-000001"
    end

    click_link "Synchronize"
    within("#synchronized-batches") do
      expect(page).to have_content "B-000001"
    end
    expect(page).to have_content "Synchronized Batch"
  end
  it "displays errors if something is wrong" do
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 40..41)
    visit "/"
    fill_in "First barcode", with: "32101113342909"
    fill_in "Call number", with: "ABID001"
    fill_in "Start box", with: 40
    fill_in "End box", with: 41
    select "Firestone Library, Vault, Manuscripts [mss]", from: "Location"
    select "Standard manuscript", from: "Container profile"
    click_button "Create Batch"

    expect(page).to have_content "Unable to find matching top containers for all boxes"
  end
end
