# frozen_string_literal: true

module Decidim
  module Civicrm
    # Forces users to have specific authorizations to access the platform.
    # Users without required authorizations are redirected to the authorizations page.
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

        flash[:warning] = I18n.t("civicrm_authorization.verification_required", scope: "decidim.verifications.authorizations")
        flash[:alert] = I18n.t("civicrm_authorization.methods_required", scope: "decidim.verifications.authorizations",
                                                                         methods: missing_authorizations.values.join(", "))

        return if request.path == "/authorizations"

        redirect_to Civicrm.unauthorized_url
      end

      def missing_authorizations
        @missing_authorizations ||= Civicrm.login_required_authorizations.reject do |name, _desc|
          current_organization.available_authorizations.exclude?(name.to_s) ||
            Decidim::Authorization.exists?(user: current_user, name:)
        end
      end

      def allow_unauthorized_path?(path = request.path)
        Civicrm.allow_unauthorized_path?(path)
      end
    end
  end
end
