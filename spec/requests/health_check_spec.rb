# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health Check" do
  describe "GET /health" do
    it "has a health check" do
      get "/health.json"
      expect(response).to be_successful
    end
  end

  context "with a bad database configuration" do
    before do
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:execute) do |instance|
        raise StandardError if database.blank? || instance.pool.db_config.name == database.to_s
      end
    end

    it "errors" do
      get "/health.json"
      expect(response).not_to be_successful
      expect(response).to have_http_status :service_unavailable
    end
  end
end
