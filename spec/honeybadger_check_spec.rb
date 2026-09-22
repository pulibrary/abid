# frozen_string_literal: true
require "hanami_helper"

RSpec.describe HoneybadgerCheck do
  describe ".maintenance_window?" do
    context "when it's staging" do
      context "and in the maintenance window" do
        it "returns true" do
          allow(described_class).to receive(:env).and_return("staging")
          Timecop.freeze("2024-07-08 5:40 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq true
          end
        end
      end
      context "in the wrong day" do
        it "returns false" do
          allow(described_class).to receive(:env).and_return("staging")
          Timecop.freeze("2024-07-09 5:40 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq false
          end
        end
      end
      context "in the wrong time" do
        it "returns false" do
          allow(described_class).to receive(:env).and_return("staging")
          Timecop.freeze("2024-07-08 5:00 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq false
          end
        end
      end
    end
    context "when it's production" do
      context "and in the maintenance window" do
        it "returns true" do
          allow(described_class).to receive(:env).and_return("production")
          Timecop.freeze("2024-07-09 5:40 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq true
          end
        end
      end
      context "in the wrong day" do
        it "returns false" do
          allow(described_class).to receive(:env).and_return("production")
          Timecop.freeze("2024-07-08 5:40 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq false
          end
        end
      end
      context "in the wrong time" do
        it "returns false" do
          allow(described_class).to receive(:env).and_return("production")
          Timecop.freeze("2024-07-09 5:00 AM EDT -04:00") do
            expect(described_class.maintenance_window?).to eq false
          end
        end
      end
    end
  end
end
