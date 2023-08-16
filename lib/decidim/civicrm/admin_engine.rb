# frozen_string_literal: true

module Decidim
  module Civicrm
    # This is the engine that runs on the admin interface of decidim-civicrm.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Civicrm::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :info, only: [:index, :create]
        resources :groups, only: [:index, :show, :update] do
          collection do
            get :sync
            get :participatory_spaces
            put :toggle_auto_sync
          end
        end

        resources :membership_types, only: :index do
          collection do
            get :sync
          end
        end

        resources :meetings, only: :index do
          collection do
            get :sync
          end
        end

        resources :meeting_registrations do
          collection do
            get :sync
            put :toggle_active
          end
        end

        root to: "info#index"
      end

      initializer "decidim_civicrm.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim.civicrm.mount_admin_engine" do
        Decidim::Core::Engine.routes do
          mount Decidim::Civicrm::AdminEngine, at: "/admin/civicrm", as: "decidim_civicrm_admin"
        end
      end

      initializer "decidim.civicrm.admin_menu" do
        Decidim.menu :admin_menu do |menu|
          menu.add_item :civicrm,
                        I18n.t("menu.civicrm", scope: "decidim.admin", default: "CiViCRM"),
                        decidim_civicrm_admin.info_index_path,
                        icon_name: "people",
                        position: 5.75,
                        active: is_active_link?(decidim_civicrm_admin.info_index_path, :inclusive),
                        if: defined?(current_user) && current_user&.read_attribute("admin")
        end
      end

      def load_seed
        nil
      end
    end
  end
end
