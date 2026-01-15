require 'openssl'
require 'net/http'
require 'base64'
require 'json'

require 'omnikassa2/version'

require 'omnikassa2/helpers/access_token_provider'
require 'omnikassa2/helpers/csv_serializer'
require 'omnikassa2/helpers/signature_service'

require 'omnikassa2/models/access_token'
require 'omnikassa2/models/merchant_order'
require 'omnikassa2/models/money'
require 'omnikassa2/models/notification'
require 'omnikassa2/models/order_result_set'
require 'omnikassa2/models/order_result'

require 'omnikassa2/requests/base_request'
require 'omnikassa2/requests/order_announce_request'
require 'omnikassa2/requests/refresh_request'
require 'omnikassa2/requests/status_pull_request'

require 'omnikassa2/responses/base_response'
require 'omnikassa2/responses/order_announce_response'
require 'omnikassa2/responses/refresh_response'
require 'omnikassa2/responses/status_pull_response'

module Omnikassa2
  @@configured = false

  SETTINGS = :refresh_token, :signing_key, :base_url

  def self.config(settings)
    for setting in SETTINGS
      value = settings[setting.to_sym]
      raise ConfigError, "config setting '#{setting}' missing" if value.nil?

      class_variable_set '@@' + setting.to_s, value
    end

    @@configured = true
  end

  def self.configured?
    @@configured
  end

  def self.refresh_token
    @@refresh_token
  end

  def self.signing_key
    Base64.decode64(@@signing_key)
  end

  def self.base_url
    case @@base_url
    when :production
      'https://betalen.rabobank.nl/omnikassa-api'
    when :sandbox
      'https://betalen.rabobank.nl/omnikassa-api-sandbox'
    else
      @@base_url
    end
  end

  def self.announce_order(order_announcement)
    response = Omnikassa2::OrderAnnounceRequest.new(order_announcement).send

    raise response.error_class, response.to_s unless response.success?
    raise Omnikassa2::InvalidSignatureError unless response.valid_signature?

    response
  end

  def self.status_pull(notification)
    more_results_available = true
    while(more_results_available) do
      raise Omnikassa2::InvalidSignatureError unless notification.valid_signature?
      raise Omnikassa2::ExpiringNotificationError if notification.expiring?

      response = Omnikassa2::StatusPullRequest.new(notification).send

      raise response.error_class, response.to_s unless response.success?
      raise Omnikassa2::InvalidSignatureError unless response.valid_signature?

      result_set = response.order_result_set
      result_set.order_results.each do |order_result|
        yield order_result
      end

      more_results_available = result_set.more_order_results_available
    end
  end

  # The common base class for all exceptions raised by OmniKassa
  class OmniKassaError < StandardError
  end

  # Raised if something is wrong with the configuration parameters
  class ConfigError < OmniKassaError
  end

  class InvalidSignatureError < OmniKassaError
  end

  class ExpiringNotificationError < OmniKassaError
  end

  # For HTTP errors where Rabobank returned a valid JSON error response
  class ApiError < OmniKassaError
    def initialize(message = nil)
      super
      warn <<~WARNING.split.join(" ")
        DEPRECATION WARNING: Omnikassa2::ApiError will be merged into
        Omnikassa2::HttpError in version 2.0. Please rescue Omnikassa2::HttpError
        or Omnikassa2::OmniKassaError instead of Omnikassa2::ApiError.
      WARNING
    end
  end

  # Inherits from JSON::ParserError for backwards compatibility:
  # HTTP errors previously surfaced as JSON::ParserError when the
  # non-JSON error response body was parsed.
  class HttpError < JSON::ParserError
    def initialize(message = nil)
      super
      warn <<~WARNING.split.join(" ")
        DEPRECATION WARNING: Omnikassa2::HttpError currently inherits from
        JSON::ParserError for backwards compatibility. In version 2.0, it will
        inherit from Omnikassa2::OmniKassaError instead. Please rescue
        Omnikassa2::HttpError or Omnikassa2::OmniKassaError instead of
        JSON::ParserError.
      WARNING
    end
  end
end
