# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      module CivicrmHelpers
        def last_sync_class(object)
          return "" unless object.last_sync

          return "text-alert" if object.needs_sync?
          return "text-warning" if object.last_sync < 1.week.ago

          "text-success"
        end

        def sync_status(group)
          if group.last_sync.nil?
            "<span class='label text-warning'>#{t("decidim.civicrm.admin.not_synced")}</span>"
          elsif group.needs_sync?
            "<span class='label #{last_sync_class(group)}'>#{t("decidim.civicrm.admin.needs_sync")}</span>"
          else
            "<span class='label text-success'>#{t("decidim.civicrm.admin.synced")}</span>"
          end.html_safe
        end

        def check_icon(valid, label: false, icon: true)
          if valid
            pic = icon "check-line", class: "action-icon text-success"
            txt = "<span class='label text-success'>#{label.is_a?(String) ? label : t("decidim.civicrm.admin.enabled")}</span>"
          else
            pic = icon "close-line", class: "action-icon text-muted"
            txt = "<span class='label text-alert'>#{label.is_a?(String) ? label : t("decidim.civicrm.admin.disabled")}</span>"
          end

          txt = if label
                  icon ? "#{pic} #{txt}" : txt
                else
                  pic
                end
          txt.html_safe
        end
      end
    end
  end
end
