# frozen_string_literal: true

# Skip secrets.yml conf to facilitate development rebuilds
Decidim::Civicrm.configure do |config|
  # Configure api credentials
  config.api = {
    key: ENV.fetch("CIVICRM_VERIFICATION_API_KEY", nil),
    secret: ENV.fetch("CIVICRM_VERIFICATION_SECRET", nil),
    url: ENV.fetch("CIVICRM_VERIFICATION_URL", nil),
    version: ENV.fetch("CIVICRM_API_VERSION", nil)
  }

  # Configure omniauth secrets
  config.omniauth = {
    enabled: true,
    client_id: ENV.fetch("CIVICRM_CLIENT_ID", nil),
    client_secret: ENV.fetch("CIVICRM_CLIENT_SECRET", nil),
    site: ENV.fetch("CIVICRM_SITE", nil)
  }

  Rails.application.secrets[:omniauth][:civicrm] = config.omniauth

  # whether to send notifications to user when they auto-verified or not:
  # config.send_verification_notifications = false

  # array with civirm group ids that will automatically (cron based) syncronize contact memberships
  config.auto_sync_groups = Rails.application.secrets.dig(:civicrm, :auto_sync_groups)
end
