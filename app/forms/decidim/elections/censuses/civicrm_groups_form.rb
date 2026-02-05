# frozen_string_literal: true

require "digest"

module Decidim
  module Elections
    module Censuses
      # Voter form for CiViCRM Groups Census verification.
      class CivicrmGroupsForm < Decidim::Form
        mimic :census_data

        attribute :verification_data, Hash, default: -> { {} }

        validate :verification_data_present
        validate :contact_in_census

        def verification_data
          super&.with_indifferent_access || {}
        end

        def election
          @election ||= context.election
        end

        def voter_uid
          return nil unless @civicrm_contact

          Digest::SHA512.hexdigest(
            "civicrm-#{@civicrm_contact[:id]}-#{election.id}-#{Rails.application.secret_key_base}"
          )
        end

        def allowed_group_id
          election&.census_settings&.dig("allowed_group_id")
        end

        def verification_fields
          election&.census_settings&.dig("verification_fields") || []
        end

        private

        def contact_in_census
          return if errors.any?

          fields = build_search_fields
          if fields.blank?
            errors.add(:base, I18n.t("decidim.elections.censuses.civicrm_groups_form.no_data"))
            return
          end

          contact = find_contact_by_fields(fields)
          unless contact
            errors.add(:base, I18n.t("decidim.elections.censuses.civicrm_groups_form.invalid"))
            return
          end

          unless contact_in_group?(contact[:id])
            errors.add(:base, I18n.t("decidim.elections.censuses.civicrm_groups_form.not_in_group"))
            return
          end

          @civicrm_contact = contact
        end

        def find_contact_by_fields(fields)
          Decidim::Civicrm::Api::V4::FindContactByFields.new(fields).result
        rescue StandardError => e
          Rails.logger.error("CiviCRM census search error: #{e.message}")
          nil
        end

        def contact_in_group?(contact_id)
          return false unless civicrm_group_id

          result = Decidim::Civicrm::Api::V4::FindContactByFields.new(
            { "id" => contact_id },
            [civicrm_group_id]
          ).result
          result.present?
        rescue StandardError => e
          Rails.logger.error("CiviCRM group check error: #{e.message}")
          false
        end

        def build_search_fields
          fields = {}

          verification_fields.each do |field|
            value = verification_data&.dig(field["name"])
            fields[field["name"]] = value if value.present?
          end

          fields
        end

        def verification_data_present
          verification_fields.each do |field|
            value = verification_data&.dig(field["name"])
            next if value.present?

            errors.add(:base, I18n.t("decidim.elections.censuses.civicrm_groups_form.field_required",
                                     field: field["label"]))
          end
        end

        def civicrm_group_id
          @civicrm_group_id ||= Decidim::Civicrm::Group
                                .to_keep
                                .find_by(id: allowed_group_id)
                                &.civicrm_group_id
        end
      end
    end
  end
end
