# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin
          return permission_action unless user && user.admin?

          allow! if permission_action.subject == :civicrm

          permission_action
        end
      end
    end
  end
end
