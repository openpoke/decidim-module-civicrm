# frozen_string_literal: true

require "decidim/civicrm/api/v3"
require "decidim/civicrm/api/v4"

module Decidim
  module Civicrm
    # This namespace holds the logic to connect to the CiViCRM REST API.
    module Api
      autoload :Request, "decidim/civicrm/api/request"
      autoload :BaseQuery, "decidim/civicrm/api/base_query"
      autoload :Find, "decidim/civicrm/api/find"
      autoload :List, "decidim/civicrm/api/list"

      def self.config
        Decidim::Civicrm.api
      end

      def self.credentials
        {
          key: config[:key],
          secret: config[:secret]
        }
      end

      def self.url
        config[:url]
      end

      def self.version
        config[:version].to_s
      end
    end
  end
end
