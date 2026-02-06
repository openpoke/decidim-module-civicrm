# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      module Censuses
        # Admin form for CiViCRM Groups Census configuration.
        class CivicrmGroupsForm < Decidim::Form
          CustomField = Struct.new(:name, :label, keyword_init: true)

          mimic :civicrm_groups

          attribute :allowed_group_id, Integer
          attribute :verification_field_names, Array[String]

          validates :allowed_group_id, presence: true
          validate :at_least_one_verification_field

          def election
            context&.election
          end

          def available_groups
            return [] unless current_organization

            Decidim::Civicrm::Group.to_keep.where(organization: current_organization).order(:title)
          end

          def available_custom_fields
            return [] unless current_organization

            Rails.cache.fetch(cache_key, expires_in: 1.hour) { fetch_custom_fields }
          end

          def census_settings
            {
              "allowed_group_id" => allowed_group_id,
              "verification_fields" => normalized_verification_fields
            }
          end

          def allowed_group_id
            super.presence || persisted_group_id
          end

          def persisted_field_names
            persisted_fields.map { |f| f["name"] }
          end

          def verification_field_names
            super.presence || persisted_field_names
          end

          private

          def persisted_group_id
            election&.census_settings&.dig("allowed_group_id")
          end

          def persisted_fields
            election&.census_settings&.dig("verification_fields") || []
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
              label = key == "id" ? I18n.t("decidim.elections.admin.censuses.civicrm_groups_form.contact_id_label") : humanize_field_name(key)
              CustomField.new(name: key, label: label)
            end
          end

          def humanize_field_name(field_name)
            i18n_key = field_name.tr(".", "_")
            I18n.t(
              "decidim.elections.admin.censuses.civicrm_groups_form.custom_fields.#{i18n_key}",
              default: field_name.tr("_", " ").gsub(".", " - ")
            )
          end

          def normalized_verification_fields
            return [] if verification_field_names.blank?

            fields_hash = available_custom_fields.index_by(&:name)
            verification_field_names.compact_blank.filter_map do |name|
              field = fields_hash[name]
              next unless field

              { "name" => name, "label" => field.label, "required" => true }
            end
          end

          def at_least_one_verification_field
            return if normalized_verification_fields.any?

            errors.add(:base, I18n.t("decidim.elections.admin.censuses.civicrm_groups_form.at_least_one_field"))
          end
        end
      end
    end
  end
end
