# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class MembershipTypesController < Decidim::Admin::ApplicationController
        include Paginable
        include NeedsPermission

        helper_method :membership_types
        helper CivicrmHelpers

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        def index
          # enforce_permission_to :index, :civicrm_membership_types
          respond_to do |format|
            format.html
            format.json do
              render json: memberships_list
            end
          end
        end

        def sync
          # enforce_permission_to :update, :civicrm_membership_types

          SyncMembershipTypesJob.perform_later(current_organization.id)
          flash[:notice] = t("success", scope: "decidim.civicrm.admin.membership_types.sync")
          redirect_to decidim_civicrm_admin.membership_types_path

          # TODO: send email when complete?
        end

        private

        def memberships_list
          query = all_membership_types
          query = if params[:ids]
                    query.where(civicrm_membership_type_id: params[:ids])
                  else
                    query.where("name ILIKE ?", "%#{params[:q]}%")
                  end
          query.map do |item|
            {
              id: item.civicrm_membership_type_id,
              text: item.name
            }
          end
        end

        def membership_types
          paginate(all_membership_types)
        end

        def all_membership_types
          @all_membership_types ||= MembershipType.where(organization: current_organization).order(id: :asc)
        end
      end
    end
  end
end
