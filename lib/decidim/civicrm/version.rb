# frozen_string_literal: true

module Decidim
  # This holds the decidim-civicrm version.
  module Civicrm
    DECIDIM_VERSION = { github: "decidim/decidim", branch: "release/0.29-stable" }.freeze
    COMPAT_DECIDIM_VERSION = [">= 0.29", "< 0.30"].freeze
    VERSION = "0.7.0"
  end
end
