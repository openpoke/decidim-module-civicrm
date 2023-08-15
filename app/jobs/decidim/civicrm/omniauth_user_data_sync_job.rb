# frozen_string_literal: true

module Decidim
  module Civicrm
    class OmniauthUserDataSyncJob < ApplicationJob
      queue_as :default

      def perform(data)
        user = Decidim::User.find_by(id: data[:user_id])

        return unless user&.civicrm_identity?

        attributes = {}
        attributes[:name] = data[:name] if data[:name].present? && Civicrm.block_user_name
        attributes[:email] = data[:email] if data[:email].present? && Civicrm.block_user_email

        if attributes.present?
          user.skip_reconfirmation!
          user.update!(attributes)
        end
      end
    end
  end
end
