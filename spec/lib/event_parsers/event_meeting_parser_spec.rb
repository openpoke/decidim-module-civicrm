# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe EventParsers::EventMeetingParser, type: :class do
    subject { described_class.new(meeting) }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_event_valid_response.json").read) }

    let(:meeting) { create :meeting }
    let(:json) do
      {
        start_date: meeting.start_time.strftime("%Y%m%d"),
        end_date: meeting.end_time.strftime("%Y%m%d"),
        title: "#{meeting.participatory_space.title["ca"]}: #{meeting.title["ca"]}",
        template_id: template_id
      }
    end
    let(:template_id) { 666 }
    let(:attributes) do
      { template_id: template_id }
    end
    let(:parser_data) do
      {
        entity: "Event",
        action: "create",
        json: 1
      }
    end
    let(:result) do
      {
        "id" => "123"
      }
    end

    before do
      subject.result = result
      allow(Decidim::Civicrm).to receive(:publish_extra_event_attributes).and_return(attributes)
    end

    it "is valid" do
      expect(subject.valid?).to be(true)
    end

    it "returns data" do
      expect(subject.json).to eq(json)
      expect(subject.data).to eq(parser_data.merge(json))
    end

    it "saves data" do
      expect { subject.save! }.to change(Decidim::Civicrm::EventMeeting, :count).by(1)
    end

    context "when no result" do
      let(:result) do
        {
          "id" => ""
        }
      end

      it "don't save data" do
        expect { subject.save! }.to raise_error ActiveRecord::RecordInvalid
        expect(Decidim::Civicrm::EventMeeting.count).to eq(0)
      end
    end
  end
end
