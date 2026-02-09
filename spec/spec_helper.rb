# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)
ENV["NODE_ENV"] ||= "test"

# Enable CiviCRM omniauth for tests
ENV["CIVICRM_CLIENT_ID"] ||= "civicrm-test-client-id"
ENV["CIVICRM_CLIENT_SECRET"] ||= "civicrm-test-client-secret"
ENV["CIVICRM_SITE"] ||= "https://civicrm.example.org"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
