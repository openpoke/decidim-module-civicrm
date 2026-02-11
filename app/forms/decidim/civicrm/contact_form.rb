# frozen_string_literal: true

module Decidim
  module Civicrm
    class ContactForm < Decidim::Form
      attribute :decidim_organization_id, Integer
      attribute :decidim_user_id, Integer
      attribute :civicrm_contact_id, Integer
      attribute :civicrm_uid, Integer
      attribute :extra, Hash
      attribute :membership_types, Array
      attribute :custom_fields, Hash

      validates :decidim_organization_id, :decidim_user_id, :civicrm_contact_id, presence: true
    end
  end
end
