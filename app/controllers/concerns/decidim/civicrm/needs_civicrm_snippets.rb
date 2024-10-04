# frozen_string_literal: true

module Decidim
  module Civicrm
    module NeedsCivicrmSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets
      end

      def snippets
        @snippets ||= Decidim::Snippets.new

        unless @snippets.any?(:oauth2_civicrm)
          @snippets.add(:oauth2_civicrm, ActionController::Base.helpers.stylesheet_pack_tag("decidim_civicrm"))
          @snippets.add(:head, @snippets.for(:oauth2_civicrm))
        end

        @snippets
      end
    end
  end
end
