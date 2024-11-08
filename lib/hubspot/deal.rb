require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Deals API
  #
  # {http://developers.hubspot.com/docs/methods/deals/deals_overview}
  #
  class Deal
    ALL_DEALS_PATH = "/deals/v1/deal/paged"
    CREATE_DEAL_PATH = "/deals/v1/deal"
    DEAL_PATH = "/deals/v1/deal/:deal_id"
    RECENT_UPDATED_PATH = "/deals/v1/deal/recent/modified"
    UPDATE_DEAL_PATH = '/deals/v1/deal/:deal_id'
    DEAL_SEARCH_PATH    = '/crm/v3/objects/deals/search'

    attr_reader :properties
    attr_reader :portal_id
    attr_reader :deal_id
    attr_reader :company_ids
    attr_reader :vids

    def initialize(response_hash)
      @portal_id = response_hash["portalId"]
      @deal_id = response_hash["id"] || response_hash["dealId"]
      # Search API does not support returning associations. There's an open issue on HubSpot's side here: https://community.hubspot.com/t5/HubSpot-Ideas/Retrieving-Associated-IDs-via-HubSpot-APIv3-SearchAPI/idi-p/966730
      @company_ids = response_hash.fetch("associations", {}).fetch("associatedCompanyIds", nil)
      @vids = response_hash.fetch("associations", {}).fetch("associatedVids", nil)
      @properties = Hubspot::Utils.properties_to_hash(response_hash["properties"])
    end

    class << self
      def create!(portal_id, company_ids, vids, params={})
        #TODO: clean following hash, Hubspot::Utils should do the trick
        associations_hash = {"portalId" => portal_id, "associations" => { "associatedCompanyIds" => company_ids, "associatedVids" => vids}}
        post_data = associations_hash.merge({ properties: Hubspot::Utils.hash_to_properties(params, key_name: "name") })

        response = Hubspot::Connection.post_json(CREATE_DEAL_PATH, params: {}, body: post_data )
        new(response)
      end

      # Updates the properties of a deal
      # {http://developers.hubspot.com/docs/methods/deals/update_deal}
      # @param deal_id [Integer] hubspot deal_id
      # @param params [Hash] hash of properties to update
      # @return [boolean] success
      def update(id, properties = {})
        update!(id, properties)
      rescue Hubspot::RequestError => e
        false
      end

      # Updates the properties of a deal
      # {http://developers.hubspot.com/docs/methods/deals/update_deal}
      # @param deal_id [Integer] hubspot deal_id
      # @param params [Hash] hash of properties to update
      # @return [Hubspot::Deal] Deal record
      def update!(id, properties = {})
        request = { properties: Hubspot::Utils.hash_to_properties(properties.stringify_keys, key_name: 'name') }
        response = Hubspot::Connection.put_json(UPDATE_DEAL_PATH, params: { deal_id: id, no_parse: true }, body: request)
        response.success?
      end

      # Associate a deal with a contact or company
      # {http://developers.hubspot.com/docs/methods/deals/associate_deal}
      # Usage
      # Hubspot::Deal.associate!(45146940, [32], [52])
      def associate!(deal_id, company_ids=[], vids=[])
        company_associations = associations = company_ids.map do |id|
          { from_id: deal_id, to_id: id }
        end

        contact_associations = vids.map do |id|
          { from_id: deal_id, to_id: id}
        end

        results = []
        if company_associations.any?
          results << HubSpot::Association.batch_create("Deal", "Company", company_associations)
        end
        if contact_associations.any?
          results << HubSpot::Association.batch_create("Deal", "Contact", contact_associations)
        end

        results.all?
      end

      # Didssociate a deal with a contact or company
      # {https://developers.hubspot.com/docs/methods/deals/delete_association}
      # Usage
      # Hubspot::Deal.dissociate!(45146940, [32], [52])
      def dissociate!(deal_id, company_ids=[], vids=[])
        company_associations = company_ids.map do |id|
          { from_id: deal_id, to_id: id }
        end

        contact_associations = vids.map do |id|
          { from_id: deal_id, to_id: id }
        end

        results = []
        if company_associations.any?
          results << HubSpot::Association.batch_delete("Deal", "Company", company_associations)
        end
        if contact_associations.any?
          results << HubSpot::Association.batch_delete("Deal", "Contact", contact_associations)
        end

        results.all?
      end

      def find(deal_id)
        response = Hubspot::Connection.get_json(DEAL_PATH, { deal_id: deal_id })
        new(response)
      end

      def all(opts = {})
        path = ALL_DEALS_PATH

        response = Hubspot::Connection.get_json(path, opts)

        result = {}
        result['deals'] = response['deals'].map { |d| new(d) }
        result['offset'] = response['offset']
        result['hasMore'] = response['hasMore']
        return result
      end

      # Find recent updated deals.
      # {http://developers.hubspot.com/docs/methods/deals/get_deals_modified}
      # @param count [Integer] the amount of deals to return.
      # @param offset [Integer] pages back through recent contacts.
      def recent(opts = {})
        response = Hubspot::Connection.get_json(RECENT_UPDATED_PATH, opts)
        response['results'].map { |d| new(d) }
      end

      def find_by_search(opts = {})
        params = {
          limit: opts[:limit].presence || 100,
          after: opts[:after].presence
        }.compact
        properties = opts[:properties].presence || []

        default_sorts = [{ propertyName: "hs_lastmodifieddate", direction: "DESCENDING" }]

        response = Hubspot::Connection.post_json(DEAL_SEARCH_PATH, {
            params: {},
            body: {
              **params,
              properties: properties.compact,
              filters: (opts[:filters].presence || []),
              sorts: opts[:sorts].presence || default_sorts
            }
          }
        )

        {
          after: response.dig('paging', 'next', 'after'),
          deals: response['results'].map { |f| new(f) }
        }
      end

      # Find all deals associated to a company
      # {http://developers.hubspot.com/docs/methods/deals/get-associated-deals}
      # @param company [Hubspot::Company] the company
      # @return [Array] Array of Hubspot::Deal records
      def find_by_company(company)
        find_by_association company
      end

      # Find all deals associated to a contact
      # {http://developers.hubspot.com/docs/methods/deals/get-associated-deals}
      # @param contact [Hubspot::Contact] the contact
      # @return [Array] Array of Hubspot::Deal records
      def find_by_contact(contact)
        find_by_association contact
      end

      # Find all deals associated to a contact or company
      # @param object [Hubspot::Contact || Hubspot::Company] a contact or company
      # @return [Array] Array of Hubspot::Deal records
      def find_by_association(object)
        to_object_type = case object
                     when Hubspot::Company then "Company"
                     when Hubspot::Contact then "Contact"
                     else raise(Hubspot::InvalidParams, 'Instance type not supported')
                     end
        Hubspot::Association.all(to_object_type, object.id, "Deal")
      end
    end

    # Archives the contact in hubspot
    # {https://developers.hubspot.com/docs/methods/contacts/delete_contact}
    # @return [TrueClass] true
    def destroy!
      Hubspot::Connection.delete_json(DEAL_PATH, {deal_id: deal_id})
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end

    def [](property)
      @properties[property]
    end

    # Updates the properties of a deal
    # {https://developers.hubspot.com/docs/methods/deals/update_deal}
    # @param params [Hash] hash of properties to update
    # @return [Hubspot::Deal] self
    def update!(params)
      query = { 'properties' => Hubspot::Utils.hash_to_properties(params.stringify_keys!, key_name: 'name') }
      Hubspot::Connection.put_json(UPDATE_DEAL_PATH, params: { deal_id: deal_id }, body: query)
      @properties.merge!(params)
      self
    end
    alias_method :update, :update!
  end
end
