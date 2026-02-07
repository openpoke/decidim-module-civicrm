# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      # This controller is the abstract class from which all other controllers of
      # this engine inherit.
      #
      # Note that it inherits from `Decidim::Admin::Components::BaseController`, which
      # override its layout and provide all kinds of useful methods.
      class ApplicationController < Decidim::Admin::ApplicationController
        helper CivicrmHelpers

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        def permission_class_chain
          [::Decidim::Civicrm::Admin::Permissions] + super
        end

        before_action do
          enforce_permission_to :access, :civicrm
        end
      end
    end
  end
end
