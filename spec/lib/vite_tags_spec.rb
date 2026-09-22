# frozen_string_literal: true

require "hanami_helper"

RSpec.describe ViteTags do
  describe "when the Vite dev server is running" do
    before do
      allow(described_class).to receive(:dev_server_running?).and_return(true)
    end

    let(:origin) { described_class.vite.config.origin }
    let(:output_dir) { described_class.vite.config.public_output_dir }

    it "emits the HMR client tag" do
      expect(described_class.vite_client_tag).to eq(
        %(<script src="#{origin}#{output_dir}/@vite/client" type="module"></script>)
      )
    end

    it "serves entrypoints from the dev server rather than the manifest" do
      expect(described_class.asset_path("entrypoints/application.js")).to eq(
        "#{origin}#{output_dir}/entrypoints/application.js"
      )
    end

    it "emits no stylesheet tags, because the dev server serves CSS through the entrypoint" do
      expect(described_class.stylesheet_tags_for("entrypoints/application.js")).to eq []
      expect(described_class.vite_javascript_tag("application")).to eq(
        %(<script src="#{origin}#{output_dir}/entrypoints/application.js" type="module" crossorigin="anonymous"></script>)
      )
    end
  end

  describe "when the dev server is not running" do
    it "falls back to a conventional path for an entry the manifest does not know" do
      expect(described_class.lookup("entrypoints/no_such_entrypoint.js")).to eq(
        "file" => "/#{described_class.vite.config.public_output_dir}/entrypoints/no_such_entrypoint.js",
        "css" => []
      )
    end

    it "resolves a built entry out of the manifest" do
      expect(described_class.asset_path("entrypoints/application.js")).to start_with("/")
    end
  end
end
