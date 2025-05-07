# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::List, type: :class do
    subject { described_class.new("contact_memberships",1) }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_contact_memberships_valid_response.json").read) }

    describe "#result" do
      it_behaves_like "returns mapped array ids v4", "membership_type_id"
    end
  end
end
