module MediawikiApi
  class ApiError < StandardError
    attr_reader :code, :info

    def initialize(error)
      @code = error["code"]
      @info = error["info"]
    end

    def message
      "#{info} (#{code})"
    end
  end

  class CreateAccountError < StandardError
  end

  class LoginError < StandardError
  end

  class TokenError < StandardError
  end
end
