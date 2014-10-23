module MediawikiApi
  class ApiError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def code
      data['code']
    end

    def info
      data['info']
    end

    def to_s
      "#{info} (#{code})"
    end

    private

    def data
      @response.data || {}
    end
  end

  class CreateAccountError < StandardError
  end

  class HttpError < StandardError
    attr_reader :status

    def initialize(status)
      @status = status
    end

    def to_s
      "unexpected HTTP response (#{status})"
    end
  end

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
