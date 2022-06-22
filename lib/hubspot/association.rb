class Hubspot::Association
  OBJECT_TARGET_TO_CLASS = {
    "Contact" => Hubspot::Contact,
    "Deal" => Hubspot::Deal,
    "Company" => Hubspot::Company
  }.freeze

  ASSOCIATION_DEFINITIONS = {
    "Company" => {
      "Contact" => 2,
      "Deal" => 6,
      "Company" => 13
    },
    "Deal" => {
      "Company" => 5,
      "Contact" => 3
    },
    "Contact" => {
      "Deal" => 4
    }
  }.freeze

  class << self
    def create(object_type, object_id, to_object_type, to_object_id)
      batch_create(object_type, to_object_type, [{from_id: object_id, to_id: to_object_id}])
    end

    # Make multiple associations in a single API call
    # {https://developers.hubspot.com/docs/api/crm/associations}
    # usage:
    # Hubspot::Association.batch_create("Company", "Contact", [{from_id: 1, to_id: 2}]])
    def batch_create(from_object_type, to_object_type, associations)
      definition_id = ASSOCIATION_DEFINITIONS.dig(from_object_type, to_object_type)
      request = { inputs: associations.map { |assocation| build_create_association_body(assocation, definition_id) } }
      response = Hubspot::Connection.post_json("/crm/v4/associations/#{from_object_type}/#{to_object_type}/batch/create", params: { no_parse: true }, body: request)
      return false if response.parsed_response["errors"].present?

      response.success?
    end

    def delete(object_type, object_id, to_object_type, to_object_id)
      batch_delete(object_type, to_object_type, [{from_id: object_id, to_id: to_object_id}])
    end

    # Remove multiple associations in a single API call
    # {https://developers.hubspot.com/docs/api/crm/associations}
    # usage:
    # Hubspot::Association.batch_delete("Company", "Contact", [{ from_id: 1, to_id: 2}])
    def batch_delete(from_object_type, to_object_type, associations)
      request = { inputs: build_delete_associations_body(associations) }
      Hubspot::Connection.post_json("/crm/v4/associations/#{from_object_type}/#{to_object_type}/batch/archive", params: { no_parse: true }, body: request).success?
    end

    # Retrieve all associated resources given a source (object_type and object_id) and a relation type (to_object_type)
    # {https://developers.hubspot.com/docs/api/crm/associations}
    # Warning: it will return at most 1000 objects and make up to 1001 queries
    # Hubspot::Association.all("Company", 42, "Contact")
    def all(object_type, object_id, to_object_type)
      klass = OBJECT_TARGET_TO_CLASS[to_object_type]
      raise(Hubspot::InvalidParams, 'Object type not supported') unless klass.present?

      response = Hubspot::Connection.get_json("/crm/v4/objects/#{object_type}/#{object_id}/associations/#{to_object_type}", {})
      response['results'].map { |result| klass.find(result["toObjectId"]) }
    end

    private

    def build_create_association_body(association, definition_id)
      {
        from: {
          id: association[:from_id]
        },
        to: {
          id: association[:to_id]
        },
        types: [
          {
            associationCategory: "HUBSPOT_DEFINED",
            associationTypeId: definition_id
          }
        ]
      }
    end

    def build_delete_associations_body(associations)
      normalized_associations = associations.inject({}) do |memo, association|
        memo[association[:from_id]] ||= []
        memo[association[:from_id]] << association[:to_id]
        memo
      end

      normalized_associations.map do |from_id, to_ids|
        {
          from: {
            id: from_id
          },
          to: to_ids.map do |to_id|
            {
              id: to_id
            }
          end
        }
      end
    end
  end
end
