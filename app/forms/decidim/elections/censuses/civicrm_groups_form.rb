# frozen_string_literal: true

require "digest"

module Decidim
  module Elections
    module Censuses
      # Voter form for CiViCRM Groups Census verification.
      class CivicrmGroupsForm < Decidim::Form
        mimic :census_data

        attribute :contact_id, String
        attribute :verification_data, Hash

        validates :contact_id, presence: true

        validate :contact_in_census

        def election
          @election ||= context.election
        end

        # CRITICAL: Elections uses this for voter tracking
        def voter_uid
          return nil unless civicrm_contact

          Digest::SHA512.hexdigest(
            "civicrm-#{civicrm_contact[:id]}-#{election.id}-#{Rails.application.secret_key_base}"
          )
        end

        def allowed_group_ids
          election&.census_settings&.dig("allowed_group_ids") || []
        end

        def verification_fields
          election&.census_settings&.dig("verification_fields") || []
        end

        def civicrm_contact
          @civicrm_contact
        end

        private

        def contact_in_census
          return if errors.any?

          result = find_contact_in_civicrm
          if result.present?
            @civicrm_contact = result
          else
            errors.add(:base, I18n.t("decidim.elections.censuses.civicrm_groups_form.invalid"))
          end
        end

        def find_contact_in_civicrm
          fields = build_search_fields
          return nil if fields.blank?

          group_ids = civicrm_group_ids
          Decidim::Civicrm::Api::V4::FindContactByFields.new(fields, group_ids).result
        rescue StandardError => e
          Rails.logger.error("CiviCRM census verification error: #{e.message}")
          nil
        end

        def build_search_fields
          fields = { "id" => contact_id }

          verification_fields.each do |field|
            value = verification_data&.dig(field["name"])
            fields[field["name"]] = value if value.present?
          end

          fields
        end

        def civicrm_group_ids
          Decidim::Civicrm::Group
            .to_keep
            .where(id: allowed_group_ids)
            .pluck(:civicrm_group_id)
        end
      end
    end
  end
end
