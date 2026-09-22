# frozen_string_literal: true

require "hanami_helper"

require "form_builder"

RSpec.describe Abid::FormBuilder do
  let(:batch) { Batch.new }
  let(:builder) { described_class.new(object: batch, name_base: "batch", id_base: "batch") }

  describe ".to_sentence" do
    it "joins nothing, one, two and three or more the way the default locale did" do
      expect(described_class.to_sentence([])).to eq ""
      expect(described_class.to_sentence(["only"])).to eq "only"
      expect(described_class.to_sentence(%w[first second])).to eq "first and second"
      expect(described_class.to_sentence(%w[first second third])).to eq "first, second, and third"
    end

    it "renders the base errors of an object as a sentence" do
      batch.errors.add(:base, "First problem")
      batch.errors.add(:base, "Second problem")

      expect(builder.error_notification).to eq(
        %(<p class="alert alert-danger">First problem and Second problem</p>)
      )
    end
  end

  describe ".hidden_field_tag" do
    it "renders an escaped hidden input, as the CSRF token field did" do
      expect(described_class.hidden_field_tag("_csrf_token", %(a"&b))).to eq(
        %(<input type="hidden" name="_csrf_token" value="a&quot;&amp;b" autocomplete="off" />)
      )
    end
  end

  describe "#boolean" do
    it "checks the box when the attribute is truthy" do
      batch.generate_abid = true

      expect(builder.boolean(:generate_abid, label: "Generate ABID")).to include(%(checked="checked"))
    end

    it "leaves the box unchecked when the attribute is false" do
      batch.generate_abid = false

      html = builder.boolean(:generate_abid, label: "Generate ABID")

      expect(html).not_to include("checked")
      expect(html).to include(%(type="checkbox"))
    end
  end
end
