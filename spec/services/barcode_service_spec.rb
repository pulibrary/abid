# frozen_string_literal: true
require "rails_helper"

RSpec.describe BarcodeService do
  describe ".valid?" do
    context "with a valid barcode" do
      it "returns true" do
        barcode = "32101113342891"
        expect(described_class.valid?(barcode)).to be true
      end
    end

    context "with a barcode that has an invalid checksum" do
      it "returns false" do
        barcode = "321011133428917"
        expect(described_class.valid?(barcode)).to be false
      end
    end

    context "with a barcode that is not numeric" do
      it "returns false" do
        barcode = "32101ABC113342891"
        expect(described_class.valid?(barcode)).to be false
      end
    end
  end
  describe "#next" do
    it "returns an array of barcodes" do
      barcode = "32101113342891"
      expect(described_class.new(barcode).next(count: 2)).to eq ["32101113342909", "32101113342917"]
    end

    context "when a barcode has a leading zero" do
      it "returns an array of barcodes in the correct format" do
        barcode = "00000000000000"
        expect(described_class.new(barcode).next(count: 2)).to eq ["00000000000018", "00000000000026"]
      end
    end
  end
end
