# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Aspace::ClientFactory do
  before do
    stub_aspace_login
  end

  it "is what 'aspace.client' resolves to" do
    expect(Hanami.app["aspace.client"]).to be_a described_class
  end

  it "builds a freshly logged in client per call, as Aspace::Client.new did" do
    factory = Hanami.app["aspace.client"]

    first = factory.new
    second = factory.call

    expect(first).to be_a Aspace::Client
    expect(second).to be_a Aspace::Client
    expect(second).not_to equal first
  end
end
