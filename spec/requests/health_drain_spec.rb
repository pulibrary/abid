# frozen_string_literal: true

require "hanami_helper"

# The load balancer drains a node by creating public/remove-from-nginx, and
# config/deploy/{production,staging}.hcl restart the allocation when /health
# stops returning 200. The file is never created on disk here; the check is
# pointed at a stand-in path instead.
RSpec.describe "Health check drain file", type: :request do
  let(:drain_path) { instance_double(Pathname) }

  before do
    allow(Abid::APP_ROOT).to receive(:join).and_call_original
    allow(Abid::APP_ROOT).to receive(:join).with("public/remove-from-nginx").and_return(drain_path)
  end

  context "when the drain file is present" do
    before do
      allow(drain_path).to receive(:exist?).and_return(true)
    end

    it "fails the check so the node is taken out of the pool" do
      get "/health.json"

      expect(response).to have_http_status :service_unavailable
      body = JSON.parse(response.body)
      expect(body["status"]).to eq "ERROR"
      expect(body["results"]).to include(
        "name" => "FileAbsence", "status" => "ERROR", "message" => "public/remove-from-nginx is present"
      )
    end
  end

  context "when the drain file cannot be read" do
    before do
      allow(drain_path).to receive(:exist?).and_raise(Errno::EACCES, "public/remove-from-nginx")
    end

    it "reports the failure rather than raising, as health-monitor-rails did" do
      get "/health.json"

      expect(response).to have_http_status :service_unavailable
      body = JSON.parse(response.body)
      expect(body["results"].find { |result| result["name"] == "FileAbsence" }["message"])
        .to include "Permission denied"
    end
  end

  context "when the drain file is absent" do
    before do
      allow(drain_path).to receive(:exist?).and_return(false)
    end

    it "passes the check" do
      get "/health.json"

      expect(response).to have_http_status :ok
      expect(JSON.parse(response.body)["status"]).to eq "OK"
    end
  end
end
