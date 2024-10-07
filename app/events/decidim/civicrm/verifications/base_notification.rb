# frozen_string_literal: true

module Decidim
  module Civicrm
    module Verifications
      class BaseNotification < Decidim::Events::SimpleEvent
        def resource_path
          Decidim::Verifications::Engine.routes.url_helpers.authorizations_path
        end

        def resource_url
          Decidim::Verifications::Engine.routes.url_helpers.authorizations_url(host: resource.organization.host)
        end
      end
    end
  end
end
