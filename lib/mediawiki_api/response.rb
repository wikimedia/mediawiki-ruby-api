require 'forwardable'
require 'json'

module MediawikiApi
  # Provides access to a parsed MediaWiki API responses.
  #
  # Some types of responses, depending on the action, contain a level or two
  # of addition structure (an envelope) above the actual payload. The {#data}
  # method provides a way of easily getting at it.
  #
  # @example
  #   # http.body => '{"query": {"userinfo": {"some": "data"}}}'
  #   response = Response.new(http, ["query", "userinfo"])
  #   response.data # => { "some" => "data" }
  #
  class Response
    extend Forwardable

    def_delegators :@response, :status, :success?

    # Constructs a new response.
    #
    # @param response [Faraday::Response]
    # @param envelope [Array] Property names for expected payload nesting.
    #
    def initialize(response, envelope = [])
      @response = response
      @envelope = envelope
    end

    # Accessor for root response object values.
    #
    # @param key [String]
    #
    # @return [Object]
    #
    def [](key)
      response_object[key]
    end

    # The main payload from the parsed response, removed from its envelope.
    #
    # @return [Object]
    #
    def data
      case response_object
      when Hash
        open_envelope(response_object)
      else
        response_object
      end
    end

    # Set of error messages from the response.
    #
    # @return [Array]
    #
    def errors
      flatten_resp('errors')
    end

    # Set of warning messages from the response.
    #
    # @return [Array]
    #
    def warnings
      flatten_resp('warnings')
    end

    # Whether the response contains warnings.
    #
    # @return [true, false]
    #
    def warnings?
      !warnings.empty?
    end

    private

    def flatten_resp(str)
      if response_object[str]
        response_object[str].values.map(&:values).flatten
      else
        []
      end
    end

    def open_envelope(obj, env = @envelope)
      if !obj.is_a?(Hash) || env.nil? || env.empty? || !obj.include?(env.first)
        obj
      else
        open_envelope(obj[env.first], env[1..])
      end
    end

    def response_object
      @response_object ||= JSON.parse(@response.body)
    end
  end
end
