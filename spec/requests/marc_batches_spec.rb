# frozen_string_literal: true
require "rails_helper"

RSpec.describe MarcBatchesController do
  describe "#destroy" do
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }
    before do
      stub_admin_user(uid: "user", uri: "/users/1")
      user = User.from_cas(access_token)
      sign_in user
    end

    context "when a batch is synchronized" do
      it "does not destroy it" do
        batch = FactoryBot.create(:synchronized_marc_batch)

        delete "/marc_batches/#{batch.id}"

        expect { MarcBatch.find(batch.id) }.not_to raise_error
        expect(flash.alert).to eq "Unable to delete synchronized Batches."
      end
    end
  end
end
