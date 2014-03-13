require "faraday"
require "faraday-cookie_jar"
require "json"

module MediawikiApi
  class LoginError < StandardError
  end

  class CreateAccountError < StandardError
  end

  class TokenError < StandardError
  end

  class Client
    attr_accessor :logged_in

    def initialize(url)
      @conn = Faraday.new(url: url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.use :cookie_jar
        faraday.adapter Faraday.default_adapter
      end
      @logged_in = false
    end

    def log_in(username, password, token = nil)
      params = { action: "login", lgname: username, lgpassword: password, format: "json" }
      params[:lgtoken] = token unless token.nil?
      resp = @conn.post "", params

      data = JSON.parse(resp.body)["login"]

      case data["result"]
      when "Success"
        @logged_in = true
      when "NeedToken"
        log_in username, password, data["token"]
      else
        raise LoginError, data["result"]
      end
    end

    def create_account(username, password, token = nil)
      params = { action: "createaccount", name: username, password: password, format: "json" }
      params[:token] = token unless token.nil?
      resp = @conn.post "", params

      data = JSON.parse(resp.body)["createaccount"]

      case data["result"]
      when "Success"
        @logged_in = true
      when "NeedToken"
        create_account username, password, data["token"]
      else
        raise CreateAccountError, data["result"]
      end
    end

    def create_page(title, content)
      token = get_token "edit"
      resp = @conn.post "", { action: "edit", title: title, text: content, token: token, format: "json" }
    end

    def delete_page(title, reason)
      token = get_token "delete"
      resp = @conn.post "", { action: "delete", title: title, reason: reason, token: token, format: "json" }
    end

    protected

    def get_token(type)
      resp = @conn.get "", { action: "tokens", type: type, format: "json" }
      token_data = JSON.parse(resp.body)
      if token_data.has_key?("warnings")
        raise TokenError, token_data["warnings"]
      else
        token_data["tokens"][type + "token"]
      end
    end
  end
end
