# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Admin form for CiViCRM Groups Census configuration.
        class CivicrmGroupsForm < Decidim::Form
          mimic :civicrm_groups

          delegate :election, to: :context, allow_nil: true

          attribute :allowed_group_ids, Array[Integer]
          attribute :verification_fields, Array

          validates :allowed_group_ids, presence: true

          def organization
            election&.component&.organization
          end

          def available_groups
            return [] unless organization

            Decidim::Civicrm::Group.to_keep.where(organization: organization).order(:title)
          end

          def available_custom_fields
            return [] unless organization

            Rails.cache.fetch(cache_key, expires_in: 1.hour) { fetch_custom_fields }
          end

          def census_settings
            {
              "allowed_group_ids" => normalized_group_ids,
              "verification_fields" => normalized_verification_fields
            }
          end

          def persisted_group_ids
            election&.census_settings&.dig("allowed_group_ids") || []
          end

          def persisted_fields
            election&.census_settings&.dig("verification_fields") || []
          end

          private

          def cache_key
            "civicrm_custom_fields_#{organization.id}"
          end

          def fetch_custom_fields
            Decidim::Civicrm::Api::V4::ListContactCustomFields.new.result || []
          rescue StandardError => e
            Rails.logger.error("CiviCRM API error: #{e.message}")
            []
          end

          def normalized_group_ids
            allowed_group_ids&.reject(&:blank?)&.map(&:to_i) || []
          end

          def normalized_verification_fields
            return [] if verification_fields.blank?

            verification_fields.select { |f| f["enabled"].present? }.map do |field|
              {
                "name" => field["name"],
                "label" => field["label"],
                "required" => field["required"].present?
              }
            end
          end
        end
      end
    end
  end
end
