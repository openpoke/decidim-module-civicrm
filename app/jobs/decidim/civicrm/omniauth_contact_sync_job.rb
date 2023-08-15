# frozen_string_literal: true

module Decidim
  module Civicrm
    class OmniauthContactSyncJob < ApplicationJob
      queue_as :default

      def perform(data)
        user = Decidim::User.find_by(id: data[:user_id])

        return unless user&.civicrm_identity?

        Decidim::Civicrm::SyncContact.call(contact_form(user, data)) do
          on(:ok) do |contact|
            Rails.logger.info "OmniauthContactSyncJob: Success: Civicrm Contact #{contact.id} created for user #{contact.user&.id}"
          end

          on(:invalid) do |message|
            Rails.logger.error "OmniauthContactSyncJob: ERROR: Civicrm Contact creation error #{message}"
          end
        end
      end

      private

      def contact_form(user, data)
        @contact_form ||= Decidim::Civicrm::ContactForm.from_params({
                                                                      decidim_user_id: user.id,
                                                                      decidim_organization_id: user.decidim_organization_id,
                                                                      civicrm_contact_id: data.dig(:raw_data, :extra, :contact, :id),
                                                                      civicrm_uid: data[:uid],
                                                                      membership_types: data.dig(:raw_data, :extra, :memberships),
                                                                      extra: data.dig(:raw_data, :extra, :contact)
                                                                    })
      end
    end
  end
end
