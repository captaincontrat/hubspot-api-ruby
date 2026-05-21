# frozen_string_literal: true

require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Tasks API
  #
  # {https://developers.hubspot.com/docs/reference/api/conversations/inbox-and-messages}
  #
  class ConversationThread
    THREAD_PATH = '/conversations/v3/conversations/threads/:thread_id'

    attr_reader :properties, :id

    def initialize(response_hash)
      @id = response_hash['id']
      @properties = response_hash.deep_symbolize_keys
    end

    class << self
      def find(thread_id, with_associations: false)
        association = with_associations ? ['TICKET'] : []
        response = Hubspot::Connection.get_json(THREAD_PATH, thread_id:, association:)
        new(response)
      end
    end
  end
end
