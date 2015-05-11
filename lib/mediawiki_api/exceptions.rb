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
    attr_reader :status

    def initialize(status)
      @status = status
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
