# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class InfoController < Decidim::Admin::ApplicationController
        include Paginable
        include NeedsPermission

        helper CivicrmHelpers

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        def index
          # enforce_permission_to :index, :info
        end

        def create
          unless authorization
            flash[:alert] = I18n.t("decidim.civicrm.admin.info.create.not_found_authorization")
            redirect_to(info_index_path) && return
          end
          unless Decidim::Civicrm.authorizations.include?(authorization.name.to_sym)
            flash[:alert] = I18n.t("decidim.civicrm.admin.info.create.not_a_civicrm_authorization")
            redirect_to(info_index_path) && return
          end

          flash[:notice] = I18n.t("decidim.civicrm.admin.info.create.regenerating_authorizations", name: authorization.name)

          RebuildVerificationsJob.perform_later(authorization.name, current_organization.id)

          redirect_to info_index_path
        end

        private

        def authorization
          @authorization ||= Decidim::Verifications.find_workflow_manifest(params[:authorization])
        end
      end
    end
  end
end
