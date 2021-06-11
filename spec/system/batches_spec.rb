# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Batch management" do
  let(:user) { User.from_cas(access_token) }
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }

  before do
    stub_admin_user(uid: "user", uri: "/users/1")
    stub_resource(ead_id: "ABID001")
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 31..31)
    stub_location(ref: "/locations/23648")
    stub_container_profile(ref: "/container_profiles/18")
    stub_top_container(ref: "/repositories/4/top_containers/118271")
    stub_save_top_container(ref: "/repositories/4/top_containers/118271")
    sign_in user
  end
  it "can create and synchronize a batch" do
    visit "/"
    fill_in "First barcode", with: "32101113344905"
    fill_in "Call number", with: "ABID001"
    fill_in "Start box", with: 31
    fill_in "End box", with: 31
    select "Firestone Library, Vault, Manuscripts [mss]", from: "Location"
    select "Standard manuscript", from: "Container profile"
    click_button "Create Batch"

    # Ensure form is pre-filled for the next barcode.
    expect(page).to have_field "First barcode", with: "32101113344913"

    batch = Batch.first
    expect(batch.absolute_identifiers.size).to eq 1

    expect(page).to have_link "Synchronize All", href: "/batches/synchronize_all"

    within("#unsynchronized-batches") do
      expect(page).to have_content "B-001556"
    end

    click_link "Synchronize"
    within("#synchronized-batches") do
      expect(page).to have_content "B-001556"
    end
    expect(page).to have_content "Synchronized Batch"
  end
  it "can delete unsynchronized batches", js: true do
    batch = FactoryBot.create(:batch, user: user)
    identifier = batch.absolute_identifiers.first
    visit batches_path

    within("#unsynchronized-batches") do
      expect(page).to have_link "Delete"
      accept_confirm do
        click_link "Delete"
      end
    end

    expect(page).to have_content "Deleted Batch"
    expect(page).not_to have_content identifier.full_identifier
  end
  it "displays errors if something is wrong" do
    stub_top_container_search(ead_id: "ABID001", repository_id: "4", indicators: 40..41)
    visit "/"
    fill_in "First barcode", with: "32101113344905"
    fill_in "Call number", with: "ABID001"
    fill_in "Start box", with: 40
    fill_in "End box", with: 41
    select "Firestone Library, Vault, Manuscripts [mss]", from: "Location"
    select "Standard manuscript", from: "Container profile"
    click_button "Create Batch"

    expect(page).to have_content "Unable to find matching top containers for all boxes"
  end
  it "generates a CSV report of a batch's absolute ids" do
    FactoryBot.create(:batch, user: user)
    visit "/"
    click_link "Export as CSV"
    expect(page).to have_content "id,abid,box_number,user,barcode,location"
    expect(page).to have_content "Standard manuscript"
  end

  it "does not submit the form if you hit enter on the barcode", js: true do
    visit "/"
    fill_in "First barcode", with: "32101113342909"
    page.find("#batch_first_barcode").send_keys :return

    expect(page).not_to have_content "Start box can't be blank"
    expect(page.evaluate_script("document.activeElement.id")).to eq "batch_call_number"
  end
end
