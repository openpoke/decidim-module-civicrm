# frozen_string_literal: true

require "digest"

module Decidim
  module Civicrm
    module Verifications
      class Civicrm < Decidim::AuthorizationHandler
        validate :user_valid

        def metadata
          super.merge(
            uid:,
            contact_id: civicrm_contact&.civicrm_contact_id
          )
        end

        def unique_id
          Digest::SHA512.hexdigest(
            "#{uid}-#{Rails.application.secrets.secret_key_base}"
          )
        end

        protected

        def organization
          current_organization || user&.organization
        end

        def uid
          civicrm_contact&.civicrm_uid || user.civicrm_identity&.uid&.to_i
        end

        def civicrm_contact
          @civicrm_contact ||= Decidim::Civicrm::Contact.find_by(user:)
        end

        def civicrm_api_contact
          @civicrm_api_contact ||= Decidim::Civicrm::Api::FindUser.new(uid).result
        end

        def user_valid
          errors.add(:user, I18n.t("decidim.civicrm.errors.not_found")) if civicrm_contact.blank? && civicrm_api_contact.blank?
        end
      end
    end
  end
end
