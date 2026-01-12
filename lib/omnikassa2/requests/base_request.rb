require 'net_http_timeout_errors'

module Omnikassa2
  class BaseRequest
    def initialize(config = {})
      @access_token = config.fetch(:access_token, Omnikassa2::AccessTokenProvider.instance)
    end

    def http_method
      :get
    end

    def authorization_method
      nil
    end

    def custom_token
      nil
    end

    def content_type
      nil
    end

    def path
      '/'
    end

    def body
      nil
    end

    def response_decorator
      Omnikassa2::BaseResponse
    end

    def send
      request = request_class.new(uri, headers)
      request.body = body_raw

      http_response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(request)
      end

      response_decorator.nil? ? http_response : response_decorator.new(http_response)
    rescue *NetHttpTimeoutErrors.all => e
      raise Omnikassa2::HttpError, "Request to Rabobank timed out: #{e.message}"
    end

    def headers
      value = {}
      add_authorization_header value
      add_content_type_header value
      value
    end

    private

    def body_raw
      return nil if body.nil?
      return body if content_type.nil?

      case content_type
      when :json
        body.to_json
      end
    end

    def request_class
      case http_method
      when :get
        Net::HTTP::Get
      when :post
        Net::HTTP::Post
      when :put
        Net::HTTP::Put
      when :delete
        Net::HTTP::Delete
      end
    end

    def uri
      tmp_url = Omnikassa2.base_url + path
      URI(tmp_url)
    end

    def add_authorization_header(value)
      case authorization_method
      when :refresh_token
        value['Authorization'] = "Bearer #{Omnikassa2.refresh_token}"
      when :access_token
        value['Authorization'] = "Bearer #{@access_token}"
      when :custom_token
        value['Authorization'] = "Bearer #{custom_token}"
      end
    end

    def add_content_type_header(value)
      case content_type
      when :json
        value['Content-Type'] = 'application/json'
      end
    end
  end
end
