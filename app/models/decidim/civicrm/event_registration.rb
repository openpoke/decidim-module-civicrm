# frozen_string_literal: true

module Decidim
  module Civicrm
    class EventRegistration < ApplicationRecord
      include MarkableForDeletion

      belongs_to :event_meeting, class_name: "Decidim::Civicrm::EventMeeting"
      belongs_to :meeting_registration,
                 foreign_key: "decidim_meeting_registration_id",
                 class_name: "Decidim::Meetings::Registration",
                 optional: true

      validates :civicrm_event_registration_id, presence: true

      delegate :meeting, to: :event
      delegate :contact, to: :user

      validate :same_meeting

      def user
        meeting_registration && meeting_registration.user
      end

      def name
        extra.dig("contact", "display_name") || user&.name
      end

      def civicrm_contact_id
        extra.dig("contact", "id") || contact&.civicrm_contact_id
      end

      def status
        extra.dig("participant", "status")
      end

      def register_date
        extra.dig("participant", "register_date")&.to_date || created_at
      end

      def synchronized?
        meeting_registration.present?
      end

      private

      def same_meeting
        return if !event_meeting || !meeting_registration

        errors.add(:meeting_registration, :invalid) unless meeting_registration.meeting == event_meeting.meeting
      end
    end
  end
end
