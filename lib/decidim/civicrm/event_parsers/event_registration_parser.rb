# frozen_string_literal: true

module Decidim
  module Civicrm
    module EventParsers
      class EventRegistrationParser < EventBaseParser
        def initialize(registration)
          @resource = registration
          @resource_type = :registration
          @resource_id = @resource&.id
          @entity = "Participant"
          @action = "create"
          @model_class = EventRegistration
        end

        def json
          {
            event_id: event.civicrm_event_id,
            contact_id:
          }
        end

        def save!
          @model_class.create!({
                                 civicrm_event_registration_id: result["id"],
                                 event_meeting: event,
                                 meeting_registration: @resource,
                                 data: result,
                                 extra: extra_data
                               })
        end

        def valid?
          super
          @errors[:event_id] = "Event id is missing" if event.blank?
          @errors[:contact_id] = "Contact id is missing" if contact_id.blank?
          @errors.blank?
        end

        private

        def event
          @event ||= EventMeeting.find_by(meeting: @resource.meeting)
        end

        def extra_data
          @extra_data ||= Decidim::Civicrm::Api::FindParticipant.new(result["id"]).result[:participant]
        end

        def contact_id
          return @contact_id if @contact_id

          authorization = Decidim::Authorization.find_by(user: @resource.user, name: "civicrm")
          return unless authorization

          @contact_id = authorization.metadata["contact_id"]
        end
      end
    end
  end
end
