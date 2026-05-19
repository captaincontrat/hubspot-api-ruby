class Hubspot::Contact < Hubspot::Resource
  self.id_field = 'vid'
  self.update_method = 'post'

  ALL_PATH                = '/crm/v3/objects/contacts'
  CREATE_PATH             = '/contacts/v1/contact'
  CREATE_OR_UPDATE_PATH   = '/contacts/v1/contact/createOrUpdate/email/:email'
  DELETE_PATH             = '/contacts/v1/contact/vid/:id'
  FIND_PATH               = '/contacts/v1/contact/vid/:id/profile'
  FIND_BY_EMAIL_PATH      = '/contacts/v1/contact/email/:email/profile'
  FIND_BY_USER_TOKEN_PATH = '/contacts/v1/contact/utk/:token/profile'
  MERGE_PATH              = '/contacts/v1/contact/merge-vids/:id/'
  SEARCH_PATH             = '/contacts/v1/search/query'
  UPDATE_PATH             = '/contacts/v1/contact/vid/:id/profile'
  BATCH_UPDATE_PATH       = '/contacts/v1/contact/batch'

  class << self
    def all(opts = {})
      Hubspot::PagedCollection.new(opts) do |options, after, limit|
        request_options = options.merge(limit:)
        request_options[:after] = after if after.present?
        response = Hubspot::Connection.get_json(ALL_PATH, request_options)

        contacts = response['results'].map do |result| 
          from_result result, id_field: Hubspot::Resource.id_field 
        end
        after = response.dig('paging', 'next', 'after')
        [contacts, after, after.present?]
      end
    end

    def find_by_vid(vid)
      response = Hubspot::Connection.get_json(FIND_PATH, id: vid)
      from_result(response)
    end

    def find_by_email(email)
      response = Hubspot::Connection.get_json(FIND_BY_EMAIL_PATH, email: email)
      from_result(response)
    end

    def find_by_user_token(token)
      response = Hubspot::Connection.get_json(FIND_BY_USER_TOKEN_PATH, token: token)
      from_result(response)
    end
    alias find_by_utk find_by_user_token

    def create(email, properties = {})
      super(properties.merge('email' => email))
    end

    def create_or_update(email, properties = {})
      request = {
        properties: Hubspot::Utils.hash_to_properties(properties.stringify_keys, key_name: 'property')
      }
      response = Hubspot::Connection.post_json(CREATE_OR_UPDATE_PATH, params: { email: email }, body: request)
      from_result(response)
    end

    def search(query, opts = {})
      Hubspot::PagedCollection.new(opts) do |options, offset, limit|
        response = Hubspot::Connection.get_json(
          SEARCH_PATH,
          options.merge(q: query, offset: offset, count: limit)
        )

        contacts = response['contacts'].map { |result| from_result(result) }
        [contacts, response['offset'], response['has-more']]
      end
    end

    def merge(primary, secondary)
      Hubspot::Connection.post_json(
        MERGE_PATH,
        params: { id: primary.to_i, no_parse: true },
        body: { 'vidToMerge' => secondary.to_i }
      )

      true
    end

    def batch_update(contacts, opts = {})
      request = contacts.map do |contact|
        # Use the specified options or update with the changes
        changes = opts.empty? ? contact.changes : opts

        next if changes.empty?

        {
          'vid' => contact.id,
          'properties' => changes.map { |k, v| { 'property' => k, 'value' => v } }
        }
      end

      # Remove any objects without changes and return if there is nothing to update
      request.compact!
      return true if request.empty?

      Hubspot::Connection.post_json(
        BATCH_UPDATE_PATH,
        params: {},
        body: request
      )

      true
    end
  end

  def [](name)
    return @changes[name] if changes.key? name

    name_property = @properties[name]

    name_property.is_a?(Hash) ? name_property['value'] : name_property
  end

  def name
    [firstname, lastname].compact.join(' ')
  end

  def merge(contact)
    self.class.merge(@id, contact.to_i)
  end
end
