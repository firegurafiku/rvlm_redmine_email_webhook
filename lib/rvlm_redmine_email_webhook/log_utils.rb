module RvlmRedmineEmailWebhook

  class LogUtils

    def self.raise(type, message)
      error_message = "[rvlm_redmine_email_webhook] #{message}"
      Rails.logger.error error_message
      Kernel.raise type, error_message
    end

    def self.error(message)
      Rails.logger.error "[rvlm_redmine_email_webhook] #{message}"
    end

    def self.warn(message)
      Rails.logger.warn "[rvlm_redmine_email_webhook] #{message}"
    end

    def self.info(message)
      Rails.logger.info "[rvlm_redmine_email_webhook] #{message}"
    end
  end
end
