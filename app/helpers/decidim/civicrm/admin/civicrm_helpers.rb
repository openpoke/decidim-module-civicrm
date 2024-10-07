# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      module CivicrmHelpers
        def last_sync_class(datetime)
          return unless datetime

          return "alert" if datetime < 1.week.ago
          return "warning" if datetime < 1.day.ago

          "success"
        end

        def check_icon(valid, label: false, icon: true)
          if valid
            pic = icon "check-line", class: "action-icon text-success"
            txt = "<span class='label success'>#{t("enabled", scope: "decidim.civicrm.admin")}</span>"
          else
            pic = icon "close-line", class: "action-icon text-muted"
            txt = "<span class='label alert'>#{t("disabled", scope: "decidim.civicrm.admin")}</span>"
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
