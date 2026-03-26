require 'net/http'
require 'uri'

module RvlmRedmineEmailWebhook

  class WebhookDeliveryJob < ApplicationJob

    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 5

    def perform(request_hash)
      request = WebRequest.from_h(request_hash)

      http = Net::HTTP.new(request.uri.host, request.uri.port)
      http.use_ssl = (request.uri.scheme == 'https')

      http_request = build_http_request(request)
      http_response = http.request(http_request)

      unless http_response.is_a?(Net::HTTPSuccess)
        # Trigger a retry by raising an exception. The retry mechanism will handle the backoff and retry attempts.
        # TODO: find a more specific exception class to raise here.
        raise "Webhook delivery failed: #{request.uri}: HTTP #{http_response.code} #{http_response.message}"
      end

      LogUtils.info("Webhook delivered successfully: #{request.uri}: HTTP #{http_response.code}")
    end

    private

    def build_http_request(request)

      # Don't check for "GET" and "DELETE" here. If user wants to send a body
      # with those methods, they're in their right to do so.
      request_body_permitted = !request.body.nil?

      # TODO: named arguments here?
      http_request = Net::HTTPGenericRequest.new(
        request.method.to_s.upcase,
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
