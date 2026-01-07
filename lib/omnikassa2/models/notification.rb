module Omnikassa2
  class Notification
    EXPIRATION_MARGIN_SECONDS = 30

    attr_reader :authentication
    attr_reader :expiry
    attr_reader :expiry_raw
    attr_reader :event_name
    attr_reader :poi_id
    attr_reader :signature

    def initialize(params)
      @authentication = params.fetch(:authentication)
      @expiry = params.fetch(:expiry)
      @expiry_raw = params.fetch(:expiry_raw) { @expiry.iso8601(3) }
      @event_name = params.fetch(:event_name)
      @poi_id = params.fetch(:poi_id)
      @signature = params.fetch(:signature)
    end

    def self.from_json(json)
      hash = JSON.parse(json)
      Notification.new(
        authentication: hash['authentication'],
        expiry: Time.parse(hash['expiry']),
        expiry_raw: hash['expiry'],
        event_name: hash['eventName'],
        poi_id: hash['poiId'],
        signature: hash['signature']
      )
    end

    def expiring?
      (Time.now + EXPIRATION_MARGIN_SECONDS) - @expiry > 0
    end

    def valid_signature?
      SignatureService.validate(to_s, @signature)
    end

    def to_s
      Notification.csv_serializer.serialize(self)
    end

    private

    def self.csv_serializer
      CSVSerializer.new([
        { field: :authentication },
        { field: :expiry_raw },
        { field: :event_name },
        { field: :poi_id }
      ])
    end
  end
end
