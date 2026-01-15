module Omnikassa2
  class AccessTokenProvider
    def self.instance
      @@instance ||= AccessTokenProvider.new
      @@instance
    end

    def access_token
      refresh_token if token_needs_refresh?
      @access_token
    end

    def to_s
      access_token.to_s
    end

    private

    def initialize
      @access_token = nil
    end

    def token_needs_refresh?
      @access_token.nil? || @access_token.expiring?
    end

    def refresh_token
      response = Omnikassa2::RefreshRequest.new.send
      raise response.error_class, response.to_s unless response.success?

      @access_token = response.access_token
    end
  end
end
