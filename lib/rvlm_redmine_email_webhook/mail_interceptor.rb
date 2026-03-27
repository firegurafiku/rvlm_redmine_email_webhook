require 'set'
require_relative 'configuration'
require_relative 'log_utils'
require_relative 'web_request'

module RvlmRedmineEmailWebhook

  class MailInterceptor

    def self.delivering_email(message)
      hooks = Configuration.hooks
      return if hooks.empty?

      unique_users = get_unique_users(message)

      unique_users.each do |user|
        hooks.each do |hook_name, hook|
          begin
            request = hook.call(user, message)
            next if request.nil?

            unless request.is_a?(WebRequest)
              LogUtils.warn "Hook #{hook_name} returned #{request.class} instead of WebRequest, skipping."
              next
            end

            WebhookDeliveryJob.perform_later(request.to_h)
          rescue => e
            LogUtils.error "Error executing hook for user #{user.login}: #{e.class}: #{e.message}"
            LogUtils.error e.backtrace&.first(10)&.join("\n")
          end
        end
      end
    end

    private

    def self.get_unique_users(message)

      # The following code's branches look really verbose and unidiomatic in
      # Ruby, but hopefully they're more efficient than Array(message.to).each,
      # because it avoids creating intermediate arrays.

      unique_emails = Set.new

      if message.to.is_a?(String)
        unique_emails.add(message.to)
      else
        if message.to
          message.to.each do |email|
            unique_emails.add(email)
          end
        end
      end

      if message.cc.is_a?(String)
        unique_emails.add(message.cc)
      else
        if message.cc
          message.cc.each do |email|
            unique_emails.add(email)
          end
        end
      end

      unique_users = Set.new

      unique_emails.each do |email|
        # TODO: cache lookup results somehow.
        user = User.find_by_mail(email)
        if user
          unique_users.add(user)
        end
      end

      unique_users
    end
  end
end
