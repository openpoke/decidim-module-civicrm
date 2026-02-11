# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncContact < Decidim::Command
      # Public: Initializes the command.
      #
      # form - A contact form
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid, form.errors.full_messages) if form.invalid?

        begin
          create_contact!
          fix_memberships

          ActiveSupport::Notifications.publish("decidim.civicrm.contact.updated", contact.id)

          broadcast(:ok, @contact)
        rescue ActiveRecord::RecordNotUnique
          broadcast(:invalid, I18n.t("decidim.civicrm.contact.errors.not_unique"))
        rescue StandardError => e
          broadcast(:invalid, e.message)
        end
      end

      private

      attr_reader :form, :contact

      def create_contact!
        @contact = Contact.find_or_create_by(
          decidim_organization_id: form.decidim_organization_id,
          civicrm_contact_id: form.civicrm_contact_id
        )
        @contact.decidim_user_id = form.decidim_user_id if form.decidim_user_id
        @contact.civicrm_uid = form.civicrm_uid if form.civicrm_uid
        @contact.extra = form.extra if form.extra
        @contact.membership_types = form.membership_types if form.membership_types
        @contact.custom_fields = form.custom_fields if form.custom_fields
        @contact.save!
      end

      def fix_memberships
        contact.possible_memberships.each do |membership|
          membership.contact = contact
          membership.save!
        end
      end
    end
  end
end
