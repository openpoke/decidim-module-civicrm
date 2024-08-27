# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Civicrm
    module Admin
      module NeedsMultiselectSnippets
        extend ActiveSupport::Concern

        included do
          helper_method :snippets
        end

        def snippets
          @snippets ||= Decidim::Snippets.new

          unless @snippets.any?(:select2)
            @snippets.add(:select2, ActionController::Base.helpers.stylesheet_link_tag("https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css"))
            @snippets.add(:select2, ActionController::Base.helpers.javascript_include_tag("https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"))
            #@snippets.add(:select2, ActionController::Base.helpers.javascript_pack_tag("decidim_admin_civicrm_selects"))
            @snippets.add(:select2, ActionController::Base.helpers.stylesheet_pack_tag("decidim_admin_civicrm_selects"))
            @snippets.add(:head, @snippets.for(:select2))
          end

          @snippets
        end
      end
    end
  end
end
