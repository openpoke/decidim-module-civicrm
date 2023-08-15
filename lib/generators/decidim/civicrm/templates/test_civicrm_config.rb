# frozen_string_literal: true

# Skip secrets.yml conf to facilitate development rebuilds
Decidim::Civicrm.configure do |config|
  # Configure api credentials
  config.api = {
    api_key: "test-api-key",
    site_key: "test-site-key",
    url: "http://test.api.example.org"
  }

  # Configure omniauth secrets
  config.omniauth = {
    enabled: true,
    client_id: "test-client-id",
    client_secret: "test-client-secret",
    site: "http://test.example.org"
  }

  # whether to send notifications to user when they auto-verified or not:
  # config.send_verification_notifications = false

  # array with civirm group ids that will automatically (cron based) syncronize contact memberships
  config.default_sync_groups = Rails.application.secrets.dig(:civicrm, :default_sync_groups)
end
