# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Admin form for CiViCRM Groups Census configuration.
        class CivicrmGroupsForm < Decidim::Form
          include Decidim::Elections::Censuses::CivicrmGroupsFormMethods

          CustomField = Struct.new(:name, :label, keyword_init: true)

          mimic :civicrm_groups

          attribute :civicrm_group_id, Integer
          attribute :verification_field_names, Array[String]

          validates :civicrm_group_id, presence: true
          validate :at_least_one_verification_field

          def available_groups
            return [] unless current_organization

            Decidim::Civicrm::Group.to_keep.where(organization: current_organization).order(:title)
          end

          def selected_group
            @selected_group ||= available_groups.find_by(civicrm_group_id: civicrm_group_id)
          end

          def last_sync_date
            selected_group&.last_sync
          end

          def available_custom_fields
            return [] unless current_organization

            Rails.cache.fetch(cache_key, expires_in: 1.hour) { fetch_custom_fields }
          end

          def census_settings
            {
              "civicrm_group_id" => civicrm_group_id,
              "verification_fields" => valid_verification_field_names
            }
          end

          # Override to include form attribute logic
          def civicrm_group_id
            super.presence || persisted_group_id
          end

          def verification_field_names
            super.presence || verification_fields
          end

          private

          def persisted_group_id
            election&.census_settings&.dig("civicrm_group_id")
          end

          def cache_key
            "civicrm_custom_fields_#{current_organization.id}"
          end

          def fetch_custom_fields
            response = Decidim::Civicrm::Api::V4::ListContactCustomFields.first_item
            return [] unless response.is_a?(Hash) && response["values"]&.first

            extract_custom_field_names(response["values"].first)
          rescue StandardError => e
            Rails.logger.error("CiviCRM API error: #{e.message}")
            []
          end

          def extract_custom_field_names(contact_data)
            contact_data.keys.map do |key|
              label = "#{key} (#{humanize_field_name(key)})"
              CustomField.new(name: key, label: label)
            end
          end

          def valid_verification_field_names
            return [] if verification_field_names.blank?

            available_names = available_custom_fields.map(&:name)
            verification_field_names.compact_blank.select { |name| available_names.include?(name) }
          end

          def at_least_one_verification_field
            return if valid_verification_field_names.any?

            errors.add(:base, I18n.t("decidim.civicrm.censuses.civicrm_groups.at_least_one_field"))
          end
        end
      end
    end
  end
end
