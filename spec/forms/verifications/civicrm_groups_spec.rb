# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  module Verifications
    describe CivicrmGroups do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api"

      let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }
      let!(:group) { create(:civicrm_group, organization: user.organization) }
      let!(:contact) { create(:civicrm_contact, user:, organization: user.organization, civicrm_contact_id: contact_id) }
      let!(:membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: contact_id) }
      let(:contact_id) { data["id"] }

      let(:attributes) do
        {
          "user" => user
        }
      end
      let(:user) { create(:user) }

      it { is_expected.to be_valid }

      context "when no groups for the user" do
        let(:membership) { nil }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
