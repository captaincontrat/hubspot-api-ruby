require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Tasks API
  #
  # {https://developers.hubspot.com/beta-docs/guides/api/crm/engagements/tasks}
  #
  class Task
    TASKS_PATH = '/crm/v3/objects/tasks'
    TASK_PATH  = '/crm/v3/objects/tasks/:task_id'
    DEFAULT_TASK_FIELDS = 'hs_timestamp,hs_task_body,hubspot_owner_id,hs_task_subject,hs_task_status,hs_task_priority,'\
      'hs_task_type,hs_task_reminders'

    attr_reader :properties, :id

    def initialize(response_hash)
      @id = response_hash['id']
      @properties = response_hash['properties'].deep_symbolize_keys
    end

    class << self
      def create!(params = {}, associations: [])
        associations_hash = { 'associations' => associations }
        properties = { hs_task_status: 'NOT_STARTED', hs_task_type: 'TODO' }.merge(params)
        post_data = associations_hash.merge({ properties: properties })

        response = Hubspot::Connection.post_json(TASKS_PATH, params: {}, body: post_data)
        new(response)
      end

      def find(task_id, properties = DEFAULT_TASK_FIELDS)
        response = Hubspot::Connection.get_json(TASK_PATH, task_id: task_id, properties:)
        new(response)
      end
    end
  end
end
