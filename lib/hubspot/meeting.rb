require 'hubspot/utils'

module Hubspot
  class Meeting
    #
    # HubSpot Meeting API
    #
    # {https://developers.hubspot.com/docs/api/crm/meetings}
    #
    MEETINGS_PATH          = '/crm/v3/objects/meetings'
    MEETING_PATH           = '/crm/v3/objects/meetings/:meeting_id'
    MEETING_SEARCH_PATH    = '/crm/v3/objects/meetings/search'
    ASSOCIATE_MEETING_PATH = '/crm/v3/objects/meetings/:meeting_id/associations/Contact/:contact_id/meeting_event_to_contact'

    BASE_PROPERTIES = %w[hubspot_owner_id hs_meeting_title hs_meeting_body hs_meeting_start_time hs_meeting_end_time].freeze

    class << self
      def all(opts = {})
        options = { properties: BASE_PROPERTIES.join(','), **opts.compact }
        response = Hubspot::Connection.get_json(MEETINGS_PATH, options)
        meetings = response['results'].map { |result| new(result) }

        {
          meetings: meetings,
          after: response.dig('paging', 'next', 'after')
        }
      end

      def find(id)
        response = Hubspot::Connection.get_json(MEETING_PATH, { meeting_id: id, properties: BASE_PROPERTIES.join(',') })
        new(response)
      end

      def find_by_contact(contact_id)
        response = Hubspot::Connection.post_json(MEETING_SEARCH_PATH, {
            params: {},
            body: {
              properties: BASE_PROPERTIES,
              filters: [{ propertyName: 'associations.contact', 'operator': 'EQ', value: contact_id }]
            }
          }
        )
        response['results'].map { |f| new(f) }
      end

      def create!(owner_id, meeting_title, meeting_body, start_date_time, end_date_time)
        body = {
          properties: {
            hs_timestamp: DateTime.now.strftime('%Q'),
            hubspot_owner_id: owner_id,
            hs_meeting_title: meeting_title,
            hs_meeting_body: meeting_body,
            hs_meeting_start_time: start_date_time.is_a?(DateTime) ? start_date_time.strftime('%Q') : start_date_time,
            hs_meeting_end_time: end_date_time.is_a?(DateTime) ? end_date_time.strftime('%Q') : end_date_time,
            hs_meeting_outcome: 'SCHEDULED'
          }
        }
        response = Hubspot::Connection.post_json(MEETINGS_PATH, params: {}, body: body)
        HashWithIndifferentAccess.new(response)
      end

      def destroy!(meeting_id)
        Hubspot::Connection.delete_json(MEETING_PATH, {meeting_id: meeting_id})
      end

      def associate!(meeting_id, contact_id)
        Hubspot::Connection.put_json(ASSOCIATE_MEETING_PATH,
                                     params: {
                                       meeting_id: meeting_id,
                                       contact_id: contact_id
                                     })
      end
    end

    attr_reader :id
    attr_reader :properties

    def initialize(hash)
      self.send(:assign_properties, hash)
    end

    private

    def assign_properties(hash)
      @id = hash['id']
      @properties = hash['properties'].deep_symbolize_keys
    end
  end
end
