require "faraday"
require "faraday-cookie_jar"
require "json"

require "mediawiki_api/exceptions"

module MediawikiApi
  class Client
    FORMAT = "json"

    attr_accessor :logged_in

    def initialize(url, log = false)
      @conn = Faraday.new(url: url) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.response :logger if log
        faraday.use :cookie_jar
        faraday.adapter Faraday.default_adapter
      end
      @logged_in = false
      @tokens = {}
    end

    def log_in(username, password, token = nil)
      params = { action: "login", lgname: username, lgpassword: password, format: FORMAT }
      params[:lgtoken] = token unless token.nil?
      resp = @conn.post "", params

      data = JSON.parse(resp.body)["login"]

      case data["result"]
      when "Success"
        @logged_in = true
        @tokens.clear
      when "NeedToken"
        log_in username, password, data["token"]
      else
        raise LoginError, data["result"]
      end
    end

    def create_account(username, password, token = nil)
      params = { action: "createaccount", name: username, password: password, format: FORMAT }
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
      action("edit", title: title, text: content)
    end

    def delete_page(title, reason)
      action("delete", title: title, reason: reason)
    end

    def upload_image(filename, path, comment, ignorewarnings)
      file = Faraday::UploadIO.new(path, "image/png")
      action("upload", token_type: "edit", filename: filename, file: file, comment: comment, ignorewarnings: ignorewarnings)
    end

    def get_wikitext(title)
      @conn.get "/w/index.php", { action: "raw", title: title }
    end

    def protect_page(title, reason, protections = "edit=sysop|move=sysop")
      action("protect", title: title, reason: reason, protections: protections)
    end

    def watch_page(title)
      action("watch", titles: title)
    end

    def unwatch_page(title)
      action("watch", titles: title, unwatch: true)
    end

    protected

    def action(name, options = {})
      options[:token] = get_token(options.delete(:token_type) || name)
      options[:titles] = Array(options[:titles]).join("|") if options.include?(:titles)

      @conn.post("", options.merge(action: name, format: FORMAT)).tap do |response|
        if response.headers.include?("mediawiki-api-error")
          raise ApiError.new(JSON.parse(response.body)["error"])
        end
      end
    end

    def get_token(type)
      unless @tokens.include?(type)
        resp = @conn.get "", { action: "tokens", type: type, format: FORMAT }
        token_data = JSON.parse(resp.body)

        raise TokenError, token_data["warnings"] if token_data.include?("warnings")

        @tokens[type] = token_data["tokens"][type + "token"]
      end

      @tokens[type]
    end
  end
end
