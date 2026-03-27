require 'net/http'
require 'socksify/http'
require 'uri'

# TODO: add the correct require lines.

module RvlmRedmineEmailWebhook

  class WebhookDeliveryJob < ApplicationJob

    # This is a temporary workaround to prevent leaking potentially sensitive
    # information in logs. Webhooks URLs are highly likely to contain access
    # tokens of some kind.
    # TODO: find a better solution.
    self.log_arguments = false

    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(request_hash)
      request = WebRequest.from_h(request_hash)

      # Create the request before starting a connection.
      http_request = build_http_request(request)

      http_response = start_connection(request) do |http|
        http.request(http_request)
      end

      log_marker = request.log_marker || "(no log marker)"

      unless http_response.is_a?(Net::HTTPSuccess)
        # Trigger a retry by raising an exception. The retry mechanism will handle the backoff and retry attempts.
        # TODO: find a more specific exception class to raise here.
        raise "Webhook delivery failed: #{log_marker}: HTTP #{http_response.code} #{http_response.message}"
      end

      LogUtils.info("Webhook delivered successfully: #{log_marker}: HTTP #{http_response.code}")
    end

    private

    def start_connection(request, &block)
      raise ArgumentError, "Block is required" unless block_given?

      proxy = request.proxy

      if proxy.nil?
        klass = Net::HTTP
      elsif proxy.is_a?(Sock5Proxy)
        klass = Net::HTTP.socks_proxy(
          proxy.host,
          proxy.port,
          username: proxy.username,
          password: proxy.password,
        )

        # TODO: excessive logging?
        LogUtils.info "Using SOCKS5 proxy for webhook delivery: #{proxy.host}:#{proxy.port} (#{proxy.username ? 'with' : 'without'} authentication)"
      else
        # TODO: do not retry on this exception.
        raise "Unsupported proxy type: #{proxy.class}"
      end

      begin
        # Note that the socksify/http, if used, will also resolve the hostname
        # through the proxy. This is usually the desired behavior.
        http = klass.new(request.uri.host, request.uri.port)
        http.use_ssl = (request.uri.scheme == 'https')
        http.read_timeout = request.read_timeout
        http.open_timeout = request.open_timeout
        http.write_timeout = request.write_timeout

        # Implicit return value.
        block.call(http)
      ensure
        http.finish if http.started?
      end
    end

    def build_http_request(request)

      # Don't check for "GET" and "DELETE" here. If user wants to send a body
      # with those methods, they're in their right to do so.
      request_body_permitted = !request.body.nil?

      # Do not convert 'request.method' to uppercase here; if the user wants
      # to use a non-standard HTTP method, they should know better.
      # TODO: named arguments here?
      http_request = Net::HTTPGenericRequest.new(
        request.method,
        request_body_permitted,
        request.response_body_permitted,
        request.uri.request_uri
      )

      request.headers&.each do |key, value|
        http_request[key] = value
      end

      if request.body
        http_request.body = request.body
        http_request.content_type ||= 'application/json'
      end

      http_request
    end
  end
end
