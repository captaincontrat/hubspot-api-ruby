module Hubspot
  #
  # HubSpot Owners API
  #
  # {https://developers.hubspot.com/docs/reference/api/crm/owners/v3}
  #
  #
  class Owner
    GET_OWNER_PATH    = '/crm/v3/owners/:owner_id' # GET
    GET_OWNERS_PATH   = '/crm/v3/owners' # GET
    CREATE_OWNER_PATH = "/crm/v3/owners" # POST
    UPDATE_OWNER_PATH = '/crm/v3/owners/:owner_id' # PUT
    DELETE_OWNER_PATH = '/crm/v3/owners/:owner_id' # DELETE

    attr_reader :properties, :owner_id, :email

    def initialize(property_hash)
      @properties = property_hash
      @owner_id   = @properties['id']
      @email      = @properties['email']
    end

    def [](property)
      @properties[property]
    end

    class << self
      def all(include_archived: false, limit: 100, after: nil)
        path = GET_OWNERS_PATH
        params = {
          archived: include_archived,
          limit: limit,
          after: after
        }.compact

        response = Hubspot::Connection.get_json(path, params)
        {
          results: response['results'].map { |r| new(r) },
          pagination: {
            next: response['paging']&.dig('next', 'after'),
            total: response['total']
          }
        }
      end

      def find(id, id_property: nil)
        path = GET_OWNER_PATH
        params = { owner_id: id }
        params[:idProperty] = id_property if id_property
        response = Hubspot::Connection.get_json(path, params)
        new(response)
      end

      def find_by_email(email, include_archived: false, limit: 100, after: nil)
        path = GET_OWNERS_PATH
        params = {
          email: email,
          archived: include_archived,
          limit: limit,
          after: after
        }.compact
        response = Hubspot::Connection.get_json(path, params)
        response['results'].blank? ? nil : new(response['results'].first)
      end

      def find_by_emails(emails = [], include_archived: false)
        emails.map { |email| find_by_email(email, include_archived: include_archived) }.reject(&:nil?)
      end
    end
  end
end
