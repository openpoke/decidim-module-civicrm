# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  module Verifications
    describe CivicrmMembershipTypes do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api"

      let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }
      let!(:membership_type) { create(:civicrm_membership_type, organization: user.organization, civicrm_membership_type_id: type_id) }
      let!(:contact) { create(:civicrm_contact, user:, organization: user.organization, civicrm_contact_id: contact_id, membership_types: types) }
      let(:types) { [type_id] }
      let(:type_id) { data["values"].first["api.Membership.get"]["values"].first["id"] }
      let(:contact_id) { data["id"] }

      let(:attributes) do
        {
          "user" => user
        }
      end
      let(:user) { create(:user) }

      it { is_expected.to be_valid }

      context "when no memberships" do
        let(:types) { [] }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
