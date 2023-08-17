# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::ListContactGroups, type: :class do
    subject { described_class.new(1) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_contact_groups_valid_response.json").read) }

    describe "#result" do
      it_behaves_like "returns mapped array ids", "group_id"
    end
  end
end
