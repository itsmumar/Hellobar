class Hello::EmailDrip
  attr_reader :template, :user, :campaign_name

  def initialize(template, user, campaign_name)
    @template = template
    @user = user
    @campaign_name = campaign_name
  end

  def send
    options = {
      greeting: user.first_name.present? ? "Hi #{ user.first_name }" : 'Hello'
    }

    mailer_result = MailerGateway.send_email("Drip Campaign: #{ template.humanize }", user.email, options)
    Analytics.track(:user, user.id, 'Sent Email', analytics_email_props)

    mailer_result
  end

  def analytics_email_props
    {
      'Email Template' => template,
      'Campaign Name' => campaign_name
    }
  end
end
