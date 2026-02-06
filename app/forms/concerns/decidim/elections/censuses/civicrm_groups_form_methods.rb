# frozen_string_literal: true

module Decidim
  module Elections
    module Censuses
      # Common functionality for CiViCRM Groups forms
      module CivicrmGroupsFormMethods
        extend ActiveSupport::Concern

        def election
          @election ||= context&.election
        end

        def allowed_group_id
          election&.census_settings&.dig("allowed_group_id")
        end

        def verification_fields
          election&.census_settings&.dig("verification_fields") || []
        end

        def civicrm_group_id
          @civicrm_group_id ||= Decidim::Civicrm::Group
                                .to_keep
                                .find_by(id: allowed_group_id)
                                &.civicrm_group_id
        end

        def humanize_field_name(field_name)
          I18n.t("decidim.civicrm.censuses.civicrm_groups.custom_fields.#{field_name}", default: field_name.tr("_", " ").gsub(".", " - "))
        end
      end
    end
  end
end
