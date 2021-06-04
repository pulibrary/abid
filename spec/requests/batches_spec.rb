# frozen_string_literal: true
require "rails_helper"

RSpec.describe BatchesController do
  it "displays a form for creating a new batch on the index page" do
    get "/batches"

    expect(response.body).to have_field "Call number"
    expect(response.body).to have_field "First barcode"
    expect(response.body).to have_field "Start box"
    expect(response.body).to have_field "End box"

    expect(response.body).to have_select "Container profile", options: ["blabla"]
  end
end
