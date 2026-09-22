# frozen_string_literal: true

require "hanami_helper"

# `blank_value?` stands in for ActiveSupport's Object#blank?, which this port
# may not use.
RSpec.describe User do
  describe ".blank_value?" do
    it "treats nil and false as blank" do
      expect(described_class.send(:blank_value?, nil)).to be true
      expect(described_class.send(:blank_value?, false)).to be true
    end

    it "treats an all-whitespace String as blank" do
      expect(described_class.send(:blank_value?, "  ")).to be true
      expect(described_class.send(:blank_value?, "netid")).to be false
    end

    it "treats an empty Array or Hash as blank" do
      expect(described_class.send(:blank_value?, [])).to be true
      expect(described_class.send(:blank_value?, { a: 1 })).to be false
    end

    it "asks anything else whether it is empty, and calls it present when it cannot answer" do
      expect(described_class.send(:blank_value?, Set.new)).to be true
      expect(described_class.send(:blank_value?, Set.new([1]))).to be false
      expect(described_class.send(:blank_value?, 0)).to be false
    end
  end
end
