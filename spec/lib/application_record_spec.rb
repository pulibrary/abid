# frozen_string_literal: true

require "hanami_helper"

RSpec.describe ApplicationRecord do
  describe "query conditions" do
    # Sequel interprets a Symbol *value* as a column reference, so
    # `where(provider: :cas)` compiled to `"provider" = "cas"` and Postgres
    # rejected it. ActiveRecord cast the value to the column's type first.
    it "casts Symbol values to the column type instead of treating them as columns" do
      FactoryBot.create(:user, uid: "someone", provider: "cas")

      expect(User.find_by(provider: :cas, uid: "someone")&.uid).to eq "someone"
    end

    it "casts Integer values supplied as Strings" do
      user = FactoryBot.create(:user, uid: "someone-else", provider: "cas")

      expect(User.find_by(id: user.id.to_s)&.uid).to eq "someone-else"
    end
  end

  describe ".cast_json" do
    it "parses a JSON String, as a jsonb column round-tripped through a form field" do
      expect(described_class.cast_json(%({"barcode":"32101"}))).to eq("barcode" => "32101")
    end

    it "returns the raw value when the String is not JSON" do
      expect(described_class.cast_json("not json at all")).to eq "not json at all"
    end

    it "passes a plain Hash or Array straight through" do
      expect(described_class.cast_json("a" => 1)).to eq("a" => 1)
      expect(described_class.cast_json([1, 2])).to eq [1, 2]
    end

    # Sequel wraps jsonb in delegators that are not Hash/Array subclasses;
    # Sequel.pg_jsonb_wrap rejects them on the way back in, so they are
    # unwrapped to plain Ruby on read.
    it "unwraps Sequel's jsonb delegators" do
      expect(described_class.cast_json(Sequel.pg_jsonb_wrap("holding_id" => "22")))
        .to eq("holding_id" => "22")
      expect(described_class.cast_json(Sequel.pg_jsonb_wrap([1, 2]))).to eq [1, 2]
    end

    it "returns anything else untouched, as a JSON scalar" do
      expect(described_class.cast_json(42)).to eq 42
    end
  end

  # The app's only numericality rule is Batch#end_box, which is allow_nil and
  # on an integer column, so the "is not a number" branch is exercised here
  # through a minimal record of the same kind.
  describe "numericality validation" do
    before do
      stub_const("NumericalityTestRecord", Class.new(described_class) do
        def self.table_name = "batches"

        validates :call_number, numericality: true
        validates :end_box, numericality: { allow_nil: true }
      end)
    end

    it "rejects a value that is not a number" do
      record = NumericalityTestRecord.new(call_number: "ABID001")

      expect(record).to be_invalid
      expect(record.errors[:call_number]).to eq ["is not a number"]
    end

    it "rejects a missing value unless the rule allows nil" do
      record = NumericalityTestRecord.new

      expect(record).to be_invalid
      expect(record.errors[:call_number]).to eq ["is not a number"]
      expect(record.errors[:end_box]).to eq []
    end

    it "accepts a number" do
      record = NumericalityTestRecord.new(end_box: 3)
      record.valid?

      expect(record.errors[:end_box]).to eq []
    end
  end

  describe "association class names" do
    # `has_many :batches` has to singularise to Batch, not "Batche".
    it "singularises names ending in ches, shes, xes and sses" do
      record = User.new

      expect(record.send(:singularize_constant, :batches)).to eq "Batch"
      expect(record.send(:singularize_constant, :marc_batches)).to eq "MarcBatch"
      expect(record.send(:singularize_constant, :boxes)).to eq "Box"
      expect(record.send(:singularize_constant, :users)).to eq "User"
    end
  end
end
