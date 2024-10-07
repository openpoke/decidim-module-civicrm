# frozen_string_literal: true

module Decidim
  module Civicrm
    class EventSyncJob < ApplicationJob
      queue_as :default

      attr_reader :result

      def perform(event_name, data)
        @event_name = event_name
        @data = data
        return unless parser

        unless parser.valid?
          Rails.logger.error "Parser invalid. Not publishing event ##{data[:resource]&.id} [#{event_name}] to CiviCRM API: #{parser.error_messages}"
          return
        end

        if publish
          Rails.logger.info "Published event ##{data[:resource]&.id} [#{event_name}] with CiviCRM UID #{@result["id"]}"
          begin
            parser.result = @result
            parser.save!
          rescue StandardError => e
            Rails.logger.error "Error saving model ##{data[:resource]&.id} with CiviCRM UID #{@result["id"]} [#{e.message}]"
          end
        else
          Rails.logger.error "Error publishing event ##{data[:resource]&.id} [#{event_name}] to CiviCRM API #{@result}"
        end
      end

      def parser
        @parser ||= case @event_name
                    when "decidim.events.meetings.meeting_created"
                      Decidim::Civicrm.publish_meetings_as_events && EventParsers::EventMeetingParser.new(@data[:resource])
                    when "decidim.events.meetings.meeting_registration_confirmed"
                      if Decidim::Civicrm.publish_meeting_registrations
                        registration = Decidim::Meetings::Registration.find_by(user: @data[:affected_users]&.first, meeting: @data[:resource])
                        registration && EventParsers::EventRegistrationParser.new(registration)
                      end
                    end
      end

      private

      def publish
        request = Decidim::Civicrm::Api::Base::Request.post(parser.data)
        @result = request.response
        @result["is_error"] == 1 ? nil : @result
      rescue StandardError => e
        @result ||= {}
        @result["exception"] = e.message
        nil
      end
    end
  end
end
