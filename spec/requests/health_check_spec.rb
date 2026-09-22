# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Health Check" do
  describe "GET /health" do
    it "has a health check" do
      get "/health.json"
      expect(response).to be_successful
    end
  end

  context "with a bad database configuration" do
    before do
      allow(Hanami.app["db.gateway"].connection).to receive(:run).and_raise(StandardError)
    end

    it "errors" do
      get "/health.json"
      expect(response).not_to be_successful
      expect(response).to have_http_status :service_unavailable
    end
  end
end
