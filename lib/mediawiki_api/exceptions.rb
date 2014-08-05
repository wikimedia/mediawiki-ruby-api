module MediawikiApi
  class ApiError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def code
      data["code"]
    end

    def info
      data["info"]
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

  class LoginError < StandardError
  end

  class TokenError < StandardError
  end
end
