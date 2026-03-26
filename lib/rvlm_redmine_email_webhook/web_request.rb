require 'uri'

module RvlmRedmineEmailWebhook

  # A simple value object describing an HTTP request to be performed
  # asynchronously by the delivery job.
  class WebRequest

    attr_accessor :method, :uri, :headers, :body, :response_body_permitted

    # @param method   [String]  HTTP method (verb) as a string. Default is "POST".
    # @param uri      [URI]     The full URI to request.
    # @param headers  [Hash]    HTTP headers.
    # @param body     [String, nil]  Request body (usually JSON).
    # @param response_body_permitted [Boolean] Whether the response body is permitted. Default is true.
    def initialize(method: "POST", uri: nil, headers: {}, body: nil, response_body_permitted: true)
      if uri.nil?
        raise ArgumentError, "Parameter 'uri' is required"
      end

      @method  = method
      @uri     = uri
      @headers = headers
      @body    = body
      @response_body_permitted = response_body_permitted
    end

    # Serialize to a plain Hash so it can be passed safely to ActiveJob.
    def to_h
      {
        'uri'     => uri.to_s,
        'method'  => method.to_s,
        'headers' => headers,
        'body'    => body,
        'response_body_permitted' => response_body_permitted
      }
    end

    def self.from_h(hash)
      new(
        method:   hash['method'],
        uri:      URI.parse(hash['uri']),
        headers:  hash['headers'],
        body:     hash['body'],
        response_body_permitted: hash['response_body_permitted']
      )
    end
  end
end
