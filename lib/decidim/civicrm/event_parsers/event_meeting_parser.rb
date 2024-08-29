# frozen_string_literal: true

module Decidim
  module Civicrm
    module EventParsers
      class EventMeetingParser < EventBaseParser
        def initialize(meeting)
          @resource = meeting
          @resource_type = "Decidim::Meetings::Meeting"
          @resource_id = @resource&.id
          @entity = "Event"
          @action = "create"
          @model_class = EventMeeting
        end

        def json
          {
            start_date: @resource.start_time.strftime("%Y%m%d"),
            end_date: @resource.end_time.strftime("%Y%m%d"),
            title:
          }.merge(extra_attributes)
        end

        def save!
          @model_class.create!({
                                 civicrm_event_id: result["id"],
                                 meeting: @resource,
                                 organization: @resource.organization,
                                 data: result,
                                 extra: extra_data
                               })
        end

        private

        def extra_attributes
          return {} unless Decidim::Civicrm.publish_extra_event_attributes.is_a?(Hash)

          Decidim::Civicrm.publish_extra_event_attributes
        end

        def extra_data
          @extra_data ||= Decidim::Civicrm::Api::FindEvent.new(result["id"]).result
        end

        def title
          meeting_title = @resource.title["ca"] || @resource.title["es"] || @resource.title["en"]
          space_title = @resource.participatory_space.title["ca"] || @resource.participatory_space.title["es"] || @resource.title["en"]
          "#{space_title}: #{meeting_title}"
        end
      end
    end
  end
end
