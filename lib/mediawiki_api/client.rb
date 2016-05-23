require 'faraday'
require 'faraday-cookie_jar'
require 'json'

require 'mediawiki_api/exceptions'
require 'mediawiki_api/response'

module MediawikiApi
  # high level client for MediaWiki
  class Client
    FORMAT = 'json'

    attr_reader :cookies
    attr_accessor :logged_in

    alias_method :logged_in?, :logged_in

    def initialize(url, log = false)
      @cookies = HTTP::CookieJar.new

      @conn = Faraday.new(url: url) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.response :logger if log
        faraday.use :cookie_jar, jar: @cookies
        faraday.adapter Faraday.default_adapter
      end

      @logged_in = false
      @tokens = {}
    end

    def action(name, params = {})
      raw_action(name, params)
    rescue ApiError => e
      if e.code == 'badtoken'
        @tokens.clear # ensure fresh token on re-try
        raw_action(name, params) # no rescue this time; only re-try once.
      else
        raise # otherwise, propagate the exception
      end
    end

    def create_account(username, password)
      params = { modules: 'createaccount', token_type: false }
      d = action(:paraminfo, params).data
      params = d['modules'] && d['modules'][0] && d['modules'][0]['parameters']
      if !params || !params.map
        raise CreateAccountError, 'unexpected API response format'
      end
      params = params.map{ |o| o['name'] }

      if params.include? 'requests'
        create_account_new(username, password)
      else
        create_account_old(username, password)
      end
    end

    def create_account_new(username, password)
      # post-AuthManager
      data = action(:query, { meta: 'tokens', type: 'createaccount', token_type: false }).data
      token = data['tokens'] && data['tokens']['createaccounttoken']
      unless token
        raise CreateAccountError, 'failed to get createaccount API token'
      end

      data = action(:createaccount, {
        username: username,
        password: password,
        retype: password,
        createreturnurl: 'http://example.com', # won't be used but must be a valid URL
        createtoken: token,
        token_type: false
      }).data
      raise CreateAccountError, data['message'] if data['status'] != 'PASS'
      data
    end

    def create_account_old(username, password, token = nil)
      # pre-AuthManager
      params = { name: username, password: password, token_type: false }
      params[:token] = token unless token.nil?

      data = action(:createaccount, params).data

      case data['result']
      when 'Success'
        @logged_in = true
        @tokens.clear
      when 'NeedToken'
        data = create_account_old(username, password, data['token'])
      else
        raise CreateAccountError, data['result']
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
      raise EditError, response if response.data['result'] == 'Failure'
      response
    end

    def get_wikitext(title)
      @conn.get '/w/index.php', action: 'raw', title: title
    end

    def list(type, params = {})
      subquery(:list, type, params)
    end

    def log_in(username, password, token = nil)
      params = { lgname: username, lgpassword: password, token_type: false }
      params[:lgtoken] = token unless token.nil?

      data = action(:login, params).data

      case data['result']
      when 'Success'
        @logged_in = true
        @tokens.clear
      when 'NeedToken'
        raise LoginError, "failed to log in with the returned token '#{token}'" unless token.nil?
        data = log_in(username, password, data['token'])
      else
        raise LoginError, data['result']
      end

      data
    end

    def meta(type, params = {})
      subquery(:meta, type, params)
    end

    def prop(type, params = {})
      subquery(:prop, type, params)
    end

    def protect_page(title, reason, protections = 'edit=sysop|move=sysop')
      action(:protect, title: title, reason: reason, protections: protections)
    end

    def query(params = {})
      action(:query, { token_type: false, http_method: :get }.merge(params))
    end

    def unwatch_page(title)
      action(:watch, token_type: 'watch', titles: title, unwatch: true)
    end

    def upload_image(filename, path, comment, ignorewarnings)
      file = Faraday::UploadIO.new(path, 'image/png')
      action(:upload,
             filename: filename, file: file, comment: comment,
             ignorewarnings: ignorewarnings)
    end

    def watch_page(title)
      action(:watch, token_type: 'watch', titles: title)
    end

    protected

    def compile_parameters(parameters)
      parameters.each.with_object({}) do |(name, value), params|
        case value
        when false
          # omit it entirely
        when Array
          params[name] = value.join('|')
        else
          params[name] = value
        end
      end
    end

    def get_token(type)
      unless @tokens.include?(type)
        response = query(meta: 'tokens', type: type)
        parameter_warning = /Unrecognized value for parameter 'type'/

        if response.warnings? && response.warnings.grep(parameter_warning).any?
          raise TokenError, response.warnings.join(', ')
        end

        @tokens[type] = response.data['tokens']["#{type}token"]
      end

      @tokens[type]
    end

    def send_request(method, params, envelope)
      response = @conn.send(method, '', params)

      raise HttpError, response.status if response.status >= 400

      if response.headers.include?('mediawiki-api-error')
        raise ApiError, Response.new(response, ['error'])
      end

      Response.new(response, envelope)
    end

    def subquery(type, subtype, params = {})
      query(params.merge(type.to_sym => subtype, :envelope => ['query', subtype]))
    end

    def raw_action(name, params = {})
      name = name.to_s
      params = params.clone

      method = params.delete(:http_method) || :post
      token_type = params.delete(:token_type)
      envelope = (params.delete(:envelope) || [name]).map(&:to_s)

      params[:token] = get_token(token_type || :csrf) unless token_type == false
      params = compile_parameters(params)

      send_request(method, params.merge(action: name, format: FORMAT), envelope)
    end
  end
end
