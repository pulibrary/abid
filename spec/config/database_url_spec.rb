# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Abid::DatabaseUrl do
  describe ".port_from" do
    it "accepts an integer port" do
      expect(described_class.port_from(5432)).to eq 5432
    end

    it "accepts a numeric string port, as lando reports it" do
      expect(described_class.port_from("63604")).to eq 63_604
    end

    # `lando info` reports `"port": true` when the container is up but its
    # published port cannot be determined. That value used to be interpolated
    # straight into the connection string, producing
    # `postgres://postgres@127.0.0.1:true/abid_development` and a bare
    # URI::InvalidURIError from deep inside Sequel.
    it "raises an actionable error when lando reports a non-numeric port" do
      expect { described_class.port_from(true) }
        .to raise_error(described_class::LandoPortUnavailable, /did not report a usable database port/)
    end

    it "explains how to recover" do
      expect { described_class.port_from(nil) }
        .to raise_error(described_class::LandoPortUnavailable, /lando restart/)
    end

    it "rejects a zero or negative port" do
      expect { described_class.port_from(0) }.to raise_error(described_class::LandoPortUnavailable)
    end
  end

  describe ".build" do
    it "percent-encodes credentials so special characters survive the URL" do
      url = described_class.build(
        user: "abid", password: "p@ss w0rd", host: "db.example", port: 5432, database: "abid_production"
      )

      expect(url).to eq "postgres://abid:p%40ss%20w0rd@db.example:5432/abid_production"
    end

    it "omits the password section when there is no password" do
      url = described_class.build(
        user: "postgres", password: "", host: "127.0.0.1", port: 5432, database: "abid_development"
      )

      expect(url).to eq "postgres://postgres@127.0.0.1:5432/abid_development"
    end
  end
end
