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
    DEFAULT_TICKET_FIELDS='content,createdate,hs_lastmodifieddate,hs_object_id,hs_pipeline,hs_pipeline_stage,'\
      'hs_ticket_category,hs_ticket_priority,hubspot_owner_id,subject'

    attr_reader :properties, :id

    def initialize(response_hash)
      @id = response_hash['id']
      @properties = response_hash['properties'].deep_symbolize_keys
    end

    class << self
      def create!(params = {}, associations: [])
        associations_hash = { 'associations' => associations }
        post_data = associations_hash.merge({ properties: params })
        response = Hubspot::Connection.post_json(TICKETS_PATH, params: {}, body: post_data)
        new(response)
      end

      def update!(id, properties = {})
        request = { properties: properties }
        response = Hubspot::Connection.patch_json(TICKET_PATH, params: { ticket_id: id }, body: request)
        new(response)
      end

      def find(ticket_id, properties = DEFAULT_TICKET_FIELDS)
        response = Hubspot::Connection.get_json(TICKET_PATH, ticket_id: ticket_id, properties:)
        new(response)
      end
    end
  end
end
