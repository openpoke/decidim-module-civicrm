# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V4
          class Request
            def initialize(verify_ssl: true)
              @verify_ssl = verify_ssl
            end

            attr_accessor :response

            def self.get(entity, params, action, verify_ssl: true)
              instance = Request.new(verify_ssl: verify_ssl)
              url = "#{Decidim::Civicrm::Api.url}/#{entity}/#{action}"
              response = instance.connection.get url do |request|
                request.params = {
                  "_authx" => auth_token,
                  "params" => params.to_json
                }
              end
              raise Decidim::Civicrm::Error, response.reason_phrase unless response.success?

              instance.response = JSON.parse(response.body).to_h
              instance
            end

            def self.post(entity, params, action, verify_ssl: true)
              instance = Request.new(verify_ssl: verify_ssl)
              url = "#{Decidim::Civicrm::Api.url}/#{entity}/#{action}"

              response = instance.connection.post url do |request|
                request.params = if action == "get"
                                   { "params" => params.to_json }
                                 else
                                   params
                                 end
                request.headers["X-Civi-Auth"] = auth_token
              end
              raise Decidim::Civicrm::Error, response.reason_phrase unless response.success?

              instance.response = JSON.parse(response.body).to_h
              instance
            end

            def connection
              @connection ||= Faraday.new(ssl: { verify: @verify_ssl })
            end

            def self.auth_token
              "Bearer #{Decidim::Civicrm::Api.credentials[:api_key]}"
            end
          end
        end
      end
    end
  end
end
