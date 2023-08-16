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
        return if current_user.admin?
        return if Civicrm.login_required_authorizations.blank?
        return if current_organization.available_authorizations.blank?
        return if missing_authorizations.blank?

        flash[:warning] = I18n.t("first_login.verification_required", scope: "decidim.verifications.authorizations")
        flash[:alert] = I18n.t("first_login.methods_required", scope: "decidim.verifications.authorizations",
                                                               methods: missing_authorizations.values.join(", "))
        case request.path
        when "/authorizations"
          redirect_to decidim_verifications.first_login_authorizations_path
        when "/authorizations/first_login"
          nil
        else
          redirect_to Civicrm.unauthorized_url
        end
      end

      def missing_authorizations
        @missing_authorizations ||= Civicrm.login_required_authorizations.reject do |name, _desc|
          current_organization.available_authorizations.exclude?(name.to_s) ||
            Decidim::Authorization.exists?(user: current_user, name: name)
        end
      end

      def allow_unauthorized_path?(path = request.path)
        Civicrm.allow_unauthorized_path?(path)
      end
    end
  end
end
