module Hubspot
  #
  # HubSpot Contact lists API
  #
  class ContactList
    LISTS_PATH             = '/crm/v3/lists'
    LIST_PATH              = '/crm/v3/lists/:list_id'
    SEARCH_PATH            = LISTS_PATH + '/search'
    LIST_BATCH_PATH        = LISTS_PATH + '/batch'
    CONTACTS_PATH          = LIST_PATH + '/memberships'
    RECENT_CONTACTS_PATH   = LIST_PATH + '/memberships/join-order'
    ADD_CONTACTS_PATH      = LIST_PATH + '/memberships/add'
    REMOVE_CONTACTS_PATH   = LIST_PATH + '/memberships/remove'
    UPDATE_NAME_PATH       = LIST_PATH + '/update-list-name'
    CONTACT_OBJECT_TYPE_ID = '0-1'
    MANUAL_PROCESSING_TYPE = 'MANUAL'

    class << self
      # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/guide#create-a-list}
      def create!(opts = {})
        object_type_id = opts.delete(:object_type_id) { CONTACT_OBJECT_TYPE_ID }
        processing_type = opts.delete(:processing_type) { MANUAL_PROCESSING_TYPE }
        body = opts.merge(objectTypeId: object_type_id, processingType: processing_type)

        response = Hubspot::Connection.post_json(LISTS_PATH, params: {}, body:)
        new(response)
      end

      # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/guide#retrieve-by-searching-list-details}
      def all(opts = {})
        body = opts.delete(:body) || { query: '' }

        Hubspot::PagedCollection.new(opts) do |options, after, limit|
          response = Hubspot::Connection.post_json(
            SEARCH_PATH,
            options.merge('limit' => limit, 'offset' => after, 'offset_param' => 'after', params: {}, body:)
          )

          lists = response['lists'].map { |list| new(list) }
          after = response.dig('paging', 'next', 'after')
          [lists, after, after.present?]
        end
      end

      # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/get-list-listId}
      # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/get-lists#parameter-list-ids}
      def find(ids)
        batch_mode, path, params = case ids
                                   when Integer then [false, LIST_PATH, { list_id: ids }]
                                   when String then [false, LIST_PATH, { list_id: ids.to_i }]
                                   when Array then [true, LISTS_PATH, { listIds: ids.map(&:to_i) }]
                                   else raise Hubspot::InvalidParams, 'expecting Integer or Array of Integers parameter'
                                   end

        response = Hubspot::Connection.get_json(path, params)
        batch_mode ? response['lists'].map { |l| new(l) } : new(response)
      end
    end

    attr_reader :id, :legacy_list_id, :name, :processing_type, :properties

    def initialize(hash)
      send(:assign_properties, hash.key?('list') ? hash['list'] : hash)
    end

    # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/update-list-name}
    def update_name!(new_name)
      response = Hubspot::Connection.put_json(UPDATE_NAME_PATH, params: { list_id: id, listName: new_name }, body: {})
      send(:assign_properties, response['updatedList'])
      self
    end

    # {http://developers.hubspot.com/docs/methods/lists/delete_list}
    def destroy!
      response = Hubspot::Connection.delete_json(LIST_PATH, { list_id: id })
      @destroyed = (response.code == 204)
    end

    # {https://developers.hubspot.com/docs/api-reference/legacy/crm/lists/memberships/get-memberships-by-id}
    def contact_ids(opts = {})
      path = opts.delete(:recent) ? RECENT_CONTACTS_PATH : CONTACTS_PATH
      opts[:list_id] = id
      Hubspot::PagedCollection.new(opts) do |options, after, limit|
        response = Hubspot::Connection.get_json(
          path, options.merge('limit' => limit, 'offset' => after, 'offset_param' => 'after')
        )

        contact_ids = response['results'].pluck('recordId')
        after = response.dig('paging', 'next', 'after')
        [contact_ids, after, after.present?]
      end
    end

    # {http://developers.hubspot.com/docs/methods/lists/add_contact_to_list}
    def add(contact_ids)
      contact_ids = [contact_ids].flatten.uniq.compact
      response = Hubspot::Connection.put_json(ADD_CONTACTS_PATH, params: { list_id: id }, body: contact_ids)
      response['recordsIdsAdded']&.sort == contact_ids.sort.map(&:to_s)
    end

    # {http://developers.hubspot.com/docs/methods/lists/remove_contact_from_list}
    def remove(contact_ids)
      contact_ids = [contact_ids].flatten.uniq.compact
      response = Hubspot::Connection.put_json(REMOVE_CONTACTS_PATH, params: { list_id: id }, body: contact_ids)
      response['recordIdsRemoved']&.sort == contact_ids.sort.map(&:to_s)
    end

    def destroyed?
      !!@destroyed
    end

    private

    def assign_properties(hash)
      @id = hash['listId']
      @legacy_list_id = hash['legacyListId']
      @name = hash['name']
      @processing_type = hash['processingType']
      @properties = hash
    end
  end
end
