# frozen_string_literal: true

module Decidim
  module Civicrm
    class Menu
      def self.register_admin_civicrm_menu!
        Decidim.menu :admin_civicrm_menu do |menu|
          menu.add_item :info,
                        I18n.t("menu.info", scope: "decidim.civicrm.admin"),
                        decidim_civicrm_admin.info_index_path,
                        icon_name: "",
                        if: allowed_to?(:index, :civicrm),
                        active: is_active_link?(decidim_civicrm_admin.info_index_path)
          menu.add_item :groups,
                        I18n.t("menu.groups", scope: "decidim.civicrm.admin"),
                        decidim_civicrm_admin.groups_path,
                        icon_name: "",
                        if: allowed_to?(:index, :civicrm),
                        active: is_active_link?(decidim_civicrm_admin.groups_path)
          menu.add_item :membership_types,
                        I18n.t("menu.membership_types", scope: "decidim.civicrm.admin"),
                        decidim_civicrm_admin.membership_types_path,
                        icon_name: "",
                        if: allowed_to?(:index, :civicrm),
                        active: is_active_link?(decidim_civicrm_admin.membership_types_path)
          menu.add_item :meetings,
                        I18n.t("menu.meetings", scope: "decidim.civicrm.admin"),
                        decidim_civicrm_admin.meetings_path,
                        icon_name: "",
                        if: allowed_to?(:index, :civicrm),
                        active: is_active_link?(decidim_civicrm_admin.meetings_path)
          menu.add_item :meeting_registrations,
                        I18n.t("menu.meeting_registrations", scope: "decidim.civicrm.admin"),
                        decidim_civicrm_admin.meeting_registrations_path,
                        icon_name: "",
                        if: allowed_to?(:index, :civicrm),
                        active: is_active_link?(decidim_civicrm_admin.meeting_registrations_path)
        end
      end
    end
  end
end
