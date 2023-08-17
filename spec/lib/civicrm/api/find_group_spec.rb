# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::FindGroup, type: :class do
    subject { described_class.new(1) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_group_valid_response.json").read) }

    describe "#result" do
      it "returns a mapped object" do
        expect(subject.result).to be_a Hash
        expect(subject.result[:group_type]).to eq(data["values"].first["group_type"].map(&:to_i))
        expect(subject.result[:title]).to eq(data["values"].first["title"])
        expect(subject.result[:id]).to eq(data["values"].first["id"].to_i)
        expect(subject.result[:name]).to eq(data["values"].first["name"])
        expect(subject.result[:description]).to eq(data["values"].first["description"])
      end
    end
  end
end
