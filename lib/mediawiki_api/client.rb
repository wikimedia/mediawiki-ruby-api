require "faraday"
require "faraday-cookie_jar"
require "json"

require "mediawiki_api/exceptions"
require "mediawiki_api/response"

module MediawikiApi
  class Client
    FORMAT = "json"

    attr_accessor :logged_in

    alias logged_in? logged_in

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

    def action(name, params = {})
      name = name.to_s

      method = params.delete(:http_method) || :post
      token_type = params.delete(:token_type)
      envelope = (params.delete(:envelope) || [name]).map(&:to_s)

      params[:token] = get_token(token_type || name) unless token_type == false
      params = compile_parameters(params)

      response = @conn.send(method, "", params.merge(action: name, format: FORMAT))

      raise HttpError, response.status if response.status >= 400

      if response.headers.include?("mediawiki-api-error")
        raise ApiError, Response.new(response, ["error"])
      end

      Response.new(response, envelope)
    end

    def create_account(username, password, token = nil)
      params = { name: username, password: password, token_type: false }
      params[:token] = token unless token.nil?

      data = action(:createaccount, params).data

      case data["result"]
      when "Success"
        @logged_in = true
        @tokens.clear
      when "NeedToken"
        data = create_account(username, password, data["token"])
      else
        raise CreateAccountError, data["result"]
      end

      data
    end

    def create_page(title, content)
      edit(title: title, text: content)
    end

    def delete_page(title, reason)
      action(:delete, title: title, reason: reason)
    end

    def edit(params = {})
      response = action(:edit, params)
      raise EditError, response if response.data["result"] == "Failure"
      response
    end

    def get_wikitext(title)
      @conn.get "/w/index.php", action: "raw", title: title
    end

    def list(type, params = {})
      subquery(:list, type, params)
    end

    def log_in(username, password, token = nil)
      params = { lgname: username, lgpassword: password, token_type: false }
      params[:lgtoken] = token unless token.nil?

      data = action(:login, params).data

      case data["result"]
      when "Success"
        @logged_in = true
        @tokens.clear
      when "NeedToken"
        data = log_in(username, password, data["token"])
      else
        raise LoginError, data["result"]
      end

      data
    end

    def meta(type, params = {})
      subquery(:meta, type, params)
    end

    def prop(type, params = {})
      subquery(:prop, type, params)
    end

    def protect_page(title, reason, protections = "edit=sysop|move=sysop")
      action(:protect, title: title, reason: reason, protections: protections)
    end

    def query(params = {})
      action(:query, { token_type: false, http_method: :get }.merge(params))
    end

    def unwatch_page(title)
      action(:watch, titles: title, unwatch: true)
    end

    def upload_image(filename, path, comment, ignorewarnings)
      file = Faraday::UploadIO.new(path, "image/png")
      action(:upload, token_type: "edit", filename: filename, file: file, comment: comment, ignorewarnings: ignorewarnings)
    end

    def watch_page(title)
      action(:watch, titles: title)
    end

    protected

    def compile_parameters(parameters)
      parameters.each.with_object({}) do |(name, value), params|
        case value
        when false
          # omit it entirely
        when Array
          params[name] = value.join("|")
        else
          params[name] = value
        end
      end
    end

    def get_token(type)
      unless @tokens.include?(type)
        response = action(:tokens, type: type, http_method: :get, token_type: false)

        if response.warnings? && response.warnings.grep(/Unrecognized value for parameter 'type'/).any?
          raise TokenError, response.warnings.join(", ")
        end

        @tokens[type] = response.data["#{type}token"]
      end

      @tokens[type]
    end

    def subquery(type, subtype, params = {})
      query(params.merge(type.to_sym => subtype, :envelope => ["query", subtype]))
    end
  end
end
