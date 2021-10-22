require 'hubspot/utils'

module Hubspot
  #
  # HubSpot Custom Behavioral Events HTTP API
  #
  # {https://developers.hubspot.com/docs/api/analytics/events}
  #
  class CustomEvent
    POST_EVENT_PATH = '/events/v3/send'

    class << self
      def trigger(event_name, email, properties, options = {})
        options[:params] ||= {}
        options[:body] ||= {}
        options[:body].merge!(
          eventName: "#{Hubspot::Config.custom_event_prefix}_#{event_name}",
          email: email,
          properties: properties
        )
        Hubspot::CustomEventConnection.trigger(POST_EVENT_PATH, options).success?
      end
    end
  end
end
