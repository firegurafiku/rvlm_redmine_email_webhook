require 'net/http'
require 'uri'

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

      http = Net::HTTP.new(request.uri.host, request.uri.port)
      http.use_ssl = (request.uri.scheme == 'https')
      http.read_timeout = request.read_timeout
      http.open_timeout = request.open_timeout
      http.write_timeout = request.write_timeout

      http_request = build_http_request(request)
      http_response = http.request(http_request)

      log_marker = request.log_marker || "(no log marker)"

      unless http_response.is_a?(Net::HTTPSuccess)
        # Trigger a retry by raising an exception. The retry mechanism will handle the backoff and retry attempts.
        # TODO: find a more specific exception class to raise here.
        raise "Webhook delivery failed: #{log_marker}: HTTP #{http_response.code} #{http_response.message}"
      end

      LogUtils.info("Webhook delivered successfully: #{log_marker}: HTTP #{http_response.code}")
    end

    private

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
