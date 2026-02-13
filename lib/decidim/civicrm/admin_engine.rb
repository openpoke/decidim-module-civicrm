# frozen_string_literal: true

require "decidim/civicrm/menu"

module Decidim
  module Civicrm
    # This is the engine that runs on the admin interface of decidim-civicrm.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Civicrm::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :info, only: [:index, :create]
        resources :groups, only: [:index, :update] do
          collection do
            post :sync
            post :sync_duplicate_memberships
            get :participatory_spaces
            post :toggle_auto_sync
          end

          resources :group_members, only: :index do
            collection do
              post :sync
            end
          end
        end

        resources :membership_types, only: :index do
          collection do
            post :sync
          end
        end

        resources :meetings, only: :index do
          collection do
            post :sync
          end
        end

        resources :meeting_registrations do
          collection do
            post :sync
            post :toggle_active
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

      initializer "decidim.civicrm.menu" do
        Decidim::Civicrm::Menu.register_admin_civicrm_menu!
        Decidim::Civicrm::Menu.register_admin_civicrm_submenus!
      end

      def load_seed
        nil
      end
    end
  end
end
