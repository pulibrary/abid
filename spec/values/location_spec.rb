# frozen_string_literal: true
require "rails_helper"

RSpec.describe Location do
  describe "#pool_identifier" do
    ["scamss", "scahsvm", "scarcpxm"].each do |code|
      context "when given a #{code} classification" do
        it "returns firestone" do
          location = described_class.new("classification" => code)
          expect(location.pool_identifier).to eq "firestone"
        end
      end
    end
    ["scamudd", "prnc", "rcpph", "sc", "sls"].each do |code|
      context "when given a #{code} classification" do
        it "returns mudd" do
          location = described_class.new("classification" => code)
          expect(location.pool_identifier).to eq "mudd"
        end
      end
    end
    context "when given an unknown code" do
      it "returns global" do
        location = described_class.new("classification" => "unknown")
        expect(location.pool_identifier).to eq "global"
      end
    end
  end
end
