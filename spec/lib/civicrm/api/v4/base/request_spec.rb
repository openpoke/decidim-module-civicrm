# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim
  describe Civicrm::Api::Base::V4::Request, type: :class do
    subject { described_class }

    include_context "with stubs example api #{Decidim::Civicrm::Api.available_versions[:v4]}"

    describe "#get petition" do
      it "returns a connection instance" do
        expect(subject.get(entity, params, action).connection).to be_a(Faraday::Connection)
      end

      it "returns a response parsed into a ruby Hash" do
        expect(subject.get(entity, params, action).response).to be_a(Hash)
        expect(subject.get(entity, params, action).response).to eq(data)
      end

      context "when is not succesful" do
        let(:http_status) { 500 }
        let(:data) do
          {
            "is_error" => 1,
            "version" => 3
          }
        end

        it "throws error" do
          expect { subject.get(entity, params, action) }.to raise_error Decidim::Civicrm::Error
        end
      end
    end

    describe "#post petition" do
      let(:http_method) { :post }

      it "returns a connection instance" do
        expect(subject.post(entity, params, action).connection).to be_a(Faraday::Connection)
      end

      it "returns a response parsed into a ruby Hash" do
        expect(subject.post(entity, params, action).response).to be_a(Hash)
        expect(subject.post(entity, params, action).response).to eq(data)
      end

      context "when is not succesful" do
        let(:http_status) { 500 }
        let(:data) do
          {
            "is_error" => 1,
            "version" => 3
          }
        end

        it "throws error" do
          expect { subject.post(entity, params, action) }.to raise_error Decidim::Civicrm::Error
        end
      end
    end
  end
end
