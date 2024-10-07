# frozen_string_literal: true

module Decidim
  module Civicrm
    # A command with all the business logic to create a user from omniauth
    module CreateOmniauthRegistrationOverride
      extend ActiveSupport::Concern

      included do
        def call
          verify_oauth_signature!

          begin
            if (@identity = existing_identity)
              @user = existing_identity.user
              verify_user_confirmed(@user)

              trigger_omniauth_registration
              return broadcast(:ok, @user)
            end
            return broadcast(:invalid) if form.invalid?

            transaction do
              create_or_find_user
              @identity = create_identity
            end
            trigger_omniauth_registration

            broadcast(:ok, @user)
          rescue ActiveRecord::RecordInvalid => e
            broadcast(:error, e.record)
          end
        end
      end
    end
  end
end
