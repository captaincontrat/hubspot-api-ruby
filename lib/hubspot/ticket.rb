require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Tickets API
  #
  # {https://developers.hubspot.com/beta-docs/guides/api/crm/objects/tickets}
  #
  class Ticket
    TICKETS_PATH = '/crm/v3/objects/tickets'
    TICKET_PATH  = '/crm/v3/objects/tickets/:ticket_id'

    attr_reader :properties
    attr_reader :id

    def initialize(response_hash)
      @id = response_hash["id"]
      @properties = response_hash['properties'].deep_symbolize_keys
    end
    class << self
      def create!(params={}, contact_id: nil, company_id: nil, deal_id: nil )
        associations_hash = {"associations" => []}
        if contact_id.present?
          associations_hash["associations"] << {
            "to": { "id": contact_id },
            "types": [ { "associationCategory": "HUBSPOT_DEFINED",
                         "associationTypeId": Hubspot::Association::ASSOCIATION_DEFINITIONS['Ticket']['Contact'] } ]
          }
        end
        if company_id.present?
          associations_hash["associations"] << {
            "to": { "id": company_id },
            "types": [ { "associationCategory": "HUBSPOT_DEFINED",
                         "associationTypeId": Hubspot::Association::ASSOCIATION_DEFINITIONS['Ticket']['Company'] } ]
          }
        end
        if deal_id.present?
          associations_hash["associations"] << {
            "to": { "id": deal_id },
            "types": [ { "associationCategory": "HUBSPOT_DEFINED",
                         "associationTypeId": Hubspot::Association::ASSOCIATION_DEFINITIONS['Ticket']['Deal'] } ]
          }
        end
        post_data = associations_hash.merge({ properties: params })

        response = Hubspot::Connection.post_json(TICKETS_PATH, params: {}, body: post_data )
        new(response)
      end

      def update!(id, properties = {})
        request = { properties: properties }
        response = Hubspot::Connection.patch_json(TICKET_PATH, params: { ticket_id: id }, body: request)
        new(response)
      end

      def find(ticket_id)
        response = Hubspot::Connection.get_json(TICKET_PATH, { ticket_id: ticket_id })
        new(response)
      end
    end
  end
end
