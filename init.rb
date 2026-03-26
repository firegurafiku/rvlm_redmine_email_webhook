require_relative 'lib/rvlm_redmine_email_webhook/configuration'
require_relative 'lib/rvlm_redmine_email_webhook/log_utils'
require_relative 'lib/rvlm_redmine_email_webhook/mail_interceptor'

Redmine::Plugin.register :rvlm_redmine_email_webhook do
  name 'RVLM: Redmine Email Webhook'
  author 'Pavel Kretov'
  description <<~DESC
    Intercepts Redmine email notifications and forwards them to web endpoints.
  DESC
  version '0.0.0'
  requires_redmine version_or_higher: '6.0'
end

module RvlmRedmineEmailWebhook

  Rails.configuration.after_initialize do

    config_dir = File.join(File.dirname(__FILE__), 'config')

    Configuration.load!(config_dir)

    if Configuration.hooks.empty?
      LogUtils.info "No hooks loaded; mail interceptor is not registered."
      next
    end

    ActionMailer::Base.register_interceptor(MailInterceptor)
    LogUtils.info "Mail interceptor registered with #{Configuration.hooks.size} hook(s)."
  end
end
