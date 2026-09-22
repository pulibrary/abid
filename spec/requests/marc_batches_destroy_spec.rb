# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "MarcBatchesController destroy", type: :request do
  describe "#destroy" do
    let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }

    before do
      stub_admin_user(uid: "user", uri: "/users/1")
      stub_alma_barcode(barcode: "32101091123743")
      user = User.from_cas(access_token)
      sign_in user
    end

    context "when a batch is not synchronized" do
      it "destroys it, with its absolute identifiers" do
        batch = FactoryBot.create(:unsynchronized_marc_batch)

        delete "/marc_batches/#{batch.id}"

        expect(response).to redirect_to batches_path
        expect { MarcBatch.find(batch.id) }.to raise_error ApplicationRecord::RecordNotFound
        expect(AbsoluteIdentifier.all.size).to eq 0
        expect(flash.notice).to eq "Deleted Batch #{batch.id}"
      end
    end
  end
end
