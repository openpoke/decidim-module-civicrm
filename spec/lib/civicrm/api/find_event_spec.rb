# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::FindEvent, type: :class do
    subject { described_class.new(42) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_event_valid_response.json").read) }

    describe "#result" do
      it "returns a mapped object" do
        expect(subject.result).to be_a Hash
        expect(subject.result[:id]).to eq(data["values"].first["id"].to_i)
        expect(subject.result[:description]).to eq(data["values"].first["description"])
        expect(subject.result[:description]).to eq(data["values"].first["event_description"])
        expect(subject.result[:summary]).to eq(data["values"].first["summary"])
        expect(subject.result[:start_date]).to eq(data["values"].first["start_date"].try(:to_time))
        expect(subject.result[:start_date]).to eq(data["values"].first["event_start_date"].try(:to_time))
        expect(subject.result[:is_public]).to be_falsey
        expect(subject.result[:is_active]).to be_truthy
      end
    end
  end
end
