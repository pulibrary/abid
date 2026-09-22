# frozen_string_literal: true

require "hanami_helper"

RSpec.describe GitVersion do
  # The format Capistrano writes, which the deployed branches parse.
  let(:revisions_log_line) do
    "Branch main (at abc1234) deployed as release 20240216174259 by deploy at 2024-02-16 17:42:59"
  end

  def with_env(key, value)
    original = ENV.fetch(key, nil)
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  context "when the value is overridden by the environment" do
    it "uses GIT_SHA, BRANCH and LAST_DEPLOYED" do
      with_env("GIT_SHA", "env-sha") { expect(described_class.sha).to eq "env-sha" }
      with_env("BRANCH", "env-branch") { expect(described_class.branch).to eq "env-branch" }
      with_env("LAST_DEPLOYED", "env-date") { expect(described_class.last_deployed).to eq "env-date" }
    end

    it "ignores an empty override" do
      with_env("GIT_SHA", "") do
        expect(described_class.env_override("GIT_SHA")).to be_nil
      end
    end
  end

  context "when deployed (revisions.log is present)" do
    before do
      allow(described_class).to receive_messages(deployed?: true, revisions_log_line: revisions_log_line)
    end

    it "reads the sha out of the last log line, without the closing paren" do
      expect(described_class.sha).to eq "abc1234"
    end

    it "reads the branch out of the last log line" do
      expect(described_class.branch).to eq "main"
    end

    it "formats the release stamp as the deployment date" do
      expect(described_class.last_deployed).to eq "16 February 2024"
    end
  end

  context "when not deployed and not in development or test" do
    before do
      allow(described_class).to receive_messages(deployed?: false, development_or_test?: false)
    end

    it "falls back to the unknown placeholders" do
      expect(described_class.sha).to eq "Unknown SHA"
      expect(described_class.branch).to eq "Unknown branch"
      expect(described_class.last_deployed).to eq "Not in deployed environment"
    end
  end

  context "when in development or test" do
    it "shells out to git" do
      expect(described_class.sha).to match(/\A[0-9a-f]{40}\z/)
      expect(described_class.branch).not_to be_empty
    end
  end

  it "points at the Capistrano-era revisions.log path" do
    expect(described_class.revisions_logfile.to_s).to end_with("revisions.log")
  end
end
