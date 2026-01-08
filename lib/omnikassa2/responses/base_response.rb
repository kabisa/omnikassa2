module Omnikassa2
  class BaseResponse
    def initialize(http_response)
      @http_response = http_response
      @body = parse_body
    end

    def json_body
      @http_response.body
    end

    def body
      @body
    end

    private

    def parse_body
      return nil if @http_response.body.nil? || @http_response.body.empty?
      return nil unless success?

      JSON.parse(@http_response.body)
    rescue JSON::ParserError
      # Response body is not valid JSON
      nil
    end

    public

    def code
      @http_response.code.to_i
    end

    def message
      @http_response.message
    end

    def success?
      code >= 200 && code < 300
    end

    def to_s
      value = "Status: #{code}: #{message}\n"
      if body
        value += "Body: #{body}"
      elsif @http_response.body
        # Show (part of) raw body for error responses (may be HTML)
        value += "Body: #{@http_response.body.to_s[0, 500]}"
      else
        value += "Body: nil"
      end
      value
    end
  end
end
