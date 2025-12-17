# frozen_string_literal: true

module Decidim
  module Civicrm
    # Overrides OmniauthRegistrationsController to preserve OAuth data during TOS acceptance.
    #
    # When a new user registers via OAuth, they may need to accept Terms of Service.
    # The TOS form submission is a POST request, but OmniAuth raw_data is only available
    # on the initial GET redirect from the provider. This causes OAuth data (contact_id,
    # memberships, groups) to be lost when the form is submitted.
    #
    # This module saves OAuth data to the session on the first request and restores it
    # on subsequent requests, ensuring CiviCRM contact data is available for authorization.
    module OmniauthRawDataSession
      extend ActiveSupport::Concern

      included do
        prepend PrependedMethods
      end

      module PrependedMethods
        private

        def user_params_from_oauth_hash
          result = super
          if result.present?
            session[:civicrm_oauth_data] = result.to_json
            return result
          end

          restore_oauth_data_from_session
        end

        def restore_oauth_data_from_session
          return nil if session[:civicrm_oauth_data].blank?

          saved_data = JSON.parse(session[:civicrm_oauth_data]).deep_symbolize_keys
          # Merge saved oauth data with form params (tos_agreement, newsletter, etc.)
          form_params = params[:user]&.to_unsafe_h&.deep_symbolize_keys || {}
          saved_data.merge(form_params)
        end
      end
    end
  end
end
