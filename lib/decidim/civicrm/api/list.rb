# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class List
        attr_reader :result, :count

        def initialize(entity, id = nil, fetch_all: true, page: 0)
          klass_name = "Decidim::Civicrm::Api::V#{Decidim::Civicrm::Api.version}::List#{entity.camelize}"
          klass = klass_name.constantize

          instance = klass.new(id, fetch_all: fetch_all, page: page)
          @result = instance.result
          @count = instance.respond_to?(:count) ? instance.count : nil
        end
      end
    end
  end
end
