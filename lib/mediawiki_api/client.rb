require 'faraday'
require 'faraday-cookie_jar'
require 'json'

module MediawikiApi
  class LoginError < StandardError
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

    def create_page(title, content)
      token = get_token "edit"
      resp = @conn.post "", { action: "edit", title: title, text: content, token: token, format: "json" }
    end

    protected

    def get_token(type)
      resp = @conn.get "", { action: "tokens", type: type, format: "json" }
      JSON.parse(resp.body)["tokens"]["edittoken"]
    end
  end
end
