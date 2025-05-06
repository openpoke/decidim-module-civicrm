# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v3/shared_contexts"

module Decidim::Civicrm
  module Verifications
    describe Civicrm do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api"

      let(:data) { JSON.parse(file_fixture("v3/find_user_valid_response.json").read) }

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
