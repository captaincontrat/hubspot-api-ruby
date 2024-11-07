module Hubspot
  class TicketProperties < Properties
    CREATE_PROPERTY_PATH = '/crm/v3/properties/ticket'
    class << self
      def create!(params={})
        superclass.create!(CREATE_PROPERTY_PATH, params)
      end
    end
  end
end
