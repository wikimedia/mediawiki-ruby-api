module MediawikiApi
  # generic MediaWiki api errors
  class ApiError < StandardError
    attr_reader :response

    def initialize(response = nil)
      @response = response
    end

    def code
      response_data['code'] || '000'
    end

    def info
      response_data['info'] || 'unknown API error'
    end

    def to_s
      "#{info} (#{code})"
    end

    private

    def response_data
      if @response
        @response.data || {}
      else
        {}
      end
    end
  end

  class CreateAccountError < StandardError
  end

  # for errors from HTTP requests
  class HttpError < StandardError
    attr_reader :response, :status

    # Accepts either a Faraday::Response (preferred) or a status integer
    # (back-compat with the original signature). Passing the response
    # lets callers inspect headers (e.g. Retry-After on 429s) and the
    # body, in addition to the status code.
    def initialize(response_or_status)
      if response_or_status.respond_to?(:status)
        @response = response_or_status
        @status   = response_or_status.status
      else
        @status = response_or_status
      end
    end

    def to_s
      "unexpected HTTP response (#{status})"
    end
  end

  # for edit failures
  class EditError < ApiError
    def to_s
      'check the response data for details'
    end
  end

  class LoginError < StandardError
  end

  class TokenError < StandardError
  end
end
