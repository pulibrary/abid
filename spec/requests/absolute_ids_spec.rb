# frozen_string_literal: true
require "rails_helper"

RSpec.describe "AbsoluteIds", type: :request do
  describe "GET /" do
    it "renders a page" do
      stub_aspace_login
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
