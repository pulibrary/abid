# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "user") }

  describe ".from_cas" do
    context "and there's a user with that netid in aspace" do
      it "pulls the URI into the user and creates it" do
        stub_unauthorized_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)
        expect(user.aspace_uri).to eq "/users/1"
      end
    end
    context "when a user already exists" do
      before do
        FactoryBot.create(:user, uid: "user", provider: "cas")
      end
      it "returns a user object and updates it with the missing URI" do
        stub_unauthorized_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)
        expect(user).to be_a described_class
        expect(user.aspace_uri).to eq "/users/1"
      end
    end
  end

  describe "#authorized?" do
    context "when there's no aspace user" do
      it "returns false" do
        expect(FactoryBot.create(:user)).not_to be_authorized
      end
    end
    context "when there's no permissions set in aspace" do
      it "returns false" do
        stub_unauthorized_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)

        expect(user).not_to be_authorized
      end
    end
    context "when given an admin user" do
      it "returns true" do
        stub_admin_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)

        expect(user).to be_authorized
      end
    end
    context "when given a staff user" do
      it "returns true" do
        # Staff users aren't aspace admins, but have some permissions in some
        # repositories.
        stub_staff_user(uid: "user", uri: "/users/1")
        user = described_class.from_cas(access_token)

        expect(user).to be_authorized
      end
    end
    context "when there's a problem with the API access" do
      it "raises" do
        stub_user(uid: "user", uri: "/users/1")
        stub_request(:get, "https://aspace.test.org/staff/api/users/1").to_return(
          status: 403,
          headers: {
            "Content-Type" => "text/html"
          },
          body: "<html>\r\n<head><title>403 Forbidden</title></head>\r\n<body>\r\n<center><h1>403 Forbidden</h1></center>\r\n<hr><center>nginx/1.27.1</center>\r\n</body>\r\n</html>\r\n"
        )
        user = described_class.from_cas(access_token)

        expect { user.authorized? }.to raise_error(ArchivesSpace::ConnectionError)
      end
    end
  end
end
