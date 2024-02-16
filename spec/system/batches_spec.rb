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
    select "Firestone Library, Vault, Manuscripts Archival [scamss]", from: "Location"
    select "Standard manuscript", from: "Container profile"
    click_button "Create Batch"

    # Ensure form is pre-filled for the next barcode.
    expect(page).to have_field "First barcode", with: "32101113344913"

    batch = Batch.first
    expect(batch.absolute_identifiers.size).to eq 1

    expect(page).to have_link "Synchronize All", href: "/batches/synchronize_all"

    within("#unsynchronized-batches") do
      expect(page).to have_content "B-001569"
    end

    click_link "Synchronize"
    within("#synchronized-batches") do
      expect(page).to have_content "B-001569"
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
    select "Firestone Library, Vault, Manuscripts Archival [scamss]", from: "Location"
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

  describe "MARC Batches" do
    it "does not submit the form if you hit enter on the barcode", js: true do
      visit "/marc_batches/new"
      click_link "Delete"
      click_link "add absolute identifier"
      fill_in "Barcode", with: "32101097107245"
      page.find(".marc_batch_absolute_identifiers_barcode input").send_keys :return

      expect(page).not_to have_content "Prefix can't be blank"
      expect(page.evaluate_script("document.activeElement.id")).to end_with "_barcode"
    end

    it "generates a CSV report of a batch's absolute ids" do
      stub_alma_barcode(barcode: "32101091123743")
      FactoryBot.create(:marc_batch, user: user, absolute_identifiers: [AbsoluteIdentifier.create(barcode: "32101091123743", prefix: "N", pool_identifier: "firestone")])
      visit "/"
      click_link "Export as CSV"
      expect(page).to have_content "barcode,holding_id,abid,previous_call_number"
    end
    it "synchronizes" do
      stub_alma_barcode(barcode: "32101091123743")
      stub_alma_holding(mms_id: "9932213323506421", holding_id: "22738127790006421")
      stub_holding_update(mms_id: "9932213323506421", holding_id: "22738127790006421")
      FactoryBot.create(:unsynchronized_marc_batch, user: user)

      visit "/"

      within("#unsynchronized-batches .batch") do
        click_link "Synchronize"
      end

      expect(page).to have_content "Synchronized MARC Batch"
    end
    it "can create multiple absolute identifiers", js: true do
      stub_alma_barcode(barcode: "32101091123743")
      stub_alma_barcode(barcode: "32101097107245")
      visit "/marc_batches/new"
      fill_in "Barcode", with: "32101091123743"
      page.find(".marc_batch_absolute_identifiers_barcode input").send_keys :return

      within("#new_marc_batch > div:nth-child(3)") do
        fill_in "Barcode", with: "32101097107245"
        page.find(".marc_batch_absolute_identifiers_barcode input").send_keys :return
      end

      within("#new_marc_batch > div:nth-child(4)") do
        click_link "Delete"
      end

      click_button "Create Marc batch"

      # Ensure these options exist.
      choose("Replace Existing AbIDs")
      choose("Protect Existing AbIDs")
      expect(page).to have_content "Prefix can't be blank"
      select "Ordinary (N)", from: "Prefix"

      click_button "Create Marc batch"

      expect(page).to have_content "Created MARC Batch"

      batch = MarcBatch.last
      expect(batch.absolute_identifiers.map(&:prefix)).to contain_exactly("N", "N")

      visit root_path

      expect(page).to have_content batch.absolute_identifiers.first.full_identifier
      identifier = batch.absolute_identifiers.first

      visit root_path
      within("#unsynchronized-batches") do
        expect(page).to have_link "Delete"
        accept_confirm do
          click_link "Delete"
        end
      end

      expect(page).to have_content "Deleted Batch"
      expect(page).not_to have_content identifier.full_identifier
    end
  end
end
