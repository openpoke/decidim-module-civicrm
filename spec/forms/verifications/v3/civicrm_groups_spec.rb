# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v3/shared_contexts"

module Decidim::Civicrm
  module Verifications
    describe CivicrmGroups do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api v3"

      let(:data) { JSON.parse(file_fixture("v3/find_user_valid_response.json").read) }

      let(:attributes) do
        {
          "user" => user
        }
      end
      let(:user) { create :user }


      it { is_expected.to be_valid }

      context "when no groups for the user" do
        let(:membership) { nil }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
