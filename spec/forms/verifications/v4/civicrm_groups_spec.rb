# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  module Verifications
    describe CivicrmGroups do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api v4"

      let(:data) { JSON.parse(file_fixture("v4/find_user_valid_response.json").read) }
      let!(:group) { create(:civicrm_group, organization: user.organization) }
      let!(:contact) { create(:civicrm_contact, user:, organization: user.organization, civicrm_contact_id: contact_id) }
      let!(:membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: contact_id) }
      let(:contact_id) { data["values"].first["id"] }

      let(:attributes) do
        {
          "user" => user
        }
      end
      let(:user) { create(:user) }

      context "when everything is OK" do
        it { is_expected.to be_valid }
      end
    end
  end
end
