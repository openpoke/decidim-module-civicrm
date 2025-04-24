# frozen_string_literal: true

module Decidim
  module Civicrm
    module UpdateAccountOverride
      extend ActiveSupport::Concern

      included do
        alias_method :original_update_personal_data, :update_personal_data

        # prevent changing email or name if it is a civicrm entity
        def update_personal_data
          name = current_user.name
          email = current_user.email
          original_update_personal_data
          if current_user.civicrm_identity?
            current_user.name = name if Civicrm.block_user_name
            current_user.email = email if Civicrm.block_user_email
          end
        end
      end
    end
  end
end
