# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class EventMeetingForm < Decidim::Form
        attribute :decidim_meeting_id, Integer
        attribute :civicrm_event_id, Integer
        attribute :redirect_url, String
        attribute :redirect_active, Boolean
        validates :decidim_meeting_id, presence: true

        validate :decidim_meeting_uniqueness
        validate :mutually_exclusive
        validate :civirm_event_exists

        def meeting
          @meeting ||= Decidim::Meetings::Meeting.find(decidim_meeting_id)
        end

        private

        def decidim_meeting_uniqueness
          errors.add(:decidim_meeting_id, :taken) if EventMeeting.where(decidim_meeting_id:).where.not(id:).exists?
        end

        def mutually_exclusive
          return if civicrm_event_id.present? || redirect_url.present?

          errors.add(:civicrm_event_id, :invalid) if civicrm_event_id.blank?
          errors.add(:redirect_url, :invalid) if redirect_url.blank?
        end

        def civirm_event_exists
          return if civicrm_event_id.blank?

          event = Decidim::Civicrm::Api::FindEvent.new(civicrm_event_id)
          return if event && event.result.present?

          errors.add(:civicrm_event_id, :invalid)
        end
      end
    end
  end
end
