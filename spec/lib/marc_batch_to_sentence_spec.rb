# frozen_string_literal: true

require "hanami_helper"

# `to_sentence` is the private helper behind the barcode error messages
# ("Issue with barcodes ..."), replacing ActiveSupport's Array#to_sentence.
RSpec.describe MarcBatch do
  describe "#to_sentence" do
    subject(:batch) { described_class.new }

    it "returns an empty string for an empty list" do
      expect(batch.send(:to_sentence, [])).to eq ""
    end

    it "returns the only element for a one element list" do
      expect(batch.send(:to_sentence, ["32101"])).to eq "32101"
    end

    it "joins two elements with 'and'" do
      expect(batch.send(:to_sentence, %w[32101 32102])).to eq "32101 and 32102"
    end

    it "joins three or more elements with commas and an Oxford 'and'" do
      expect(batch.send(:to_sentence, %w[32101 32102 32103])).to eq "32101, 32102, and 32103"
    end

    it "stringifies its elements" do
      expect(batch.send(:to_sentence, [1, 2, 3])).to eq "1, 2, and 3"
    end
  end
end
