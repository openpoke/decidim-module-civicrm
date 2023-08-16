# frozen_string_literal: true

module Decidim
  module Civicrm
    # A command with all the business logic to create a user from omniauth
    module ForceAuthorization
      extend ActiveSupport::Concern

      included do
        before_action :ensure_authorization!, unless: :allow_unauthorized_path?
      end

      private

      def ensure_authorization!
        return unless user_signed_in?

        return if Civicrm.login_required_authorizations.blank?

        if missing_authorizations.present?
          flash[:warning] = I18n.t("first_login.verification_required", scope: "decidim.verifications.authorizations")
          flash[:alert] = I18n.t("first_login.methods_required", scope: "decidim.verifications.authorizations",
                                                                 methods: missing_authorizations.values.join(", "))
          redirect_to decidim_verifications.first_login_authorizations_path unless request.path == "/authorizations/first_login"
        end
      end

      def missing_authorizations
        Civicrm.login_required_authorizations.reject do |name, _desc|
          Decidim::Authorization.exists?(user: current_user, name: name)
        end
      end

      def allow_unauthorized_path?
        return false if request.path.in? %w(/authorizations /authorizations/first_login)
        return true if unauthorized_paths.any? { |path| /^#{path}/.match?(request.path) }

        false
      end

      def unauthorized_paths
        %w(/locale /authorizations /users /account/delete /users /pages)
      end
    end
  end
end
