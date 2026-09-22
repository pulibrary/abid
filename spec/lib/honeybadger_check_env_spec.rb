# frozen_string_literal: true

require "hanami_helper"

# Every other example stubs `.env`, so this is the one place the real method
# runs. It stands in for `Rails.env`, which the maintenance window read.
RSpec.describe HoneybadgerCheck do
  describe ".env" do
    it "returns the application environment" do
      expect(described_class.env).to eq Abid.env
      expect(described_class.env).to eq "test"
    end
  end
end
