# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::ListContactGroups, type: :class do
    subject { described_class.new(1) }

    include_context "with stubs example api #{Decidim::Civicrm::Api.available_versions[:v4]}"

    let(:data) { JSON.parse(file_fixture("v4/list_contact_groups_valid_response.json").read) }

    describe "#result" do
      it_behaves_like "returns mapped array ids #{Decidim::Civicrm::Api.available_versions[:v4]}", "group_id"
    end
  end
end
