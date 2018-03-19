class ContactFormMailer < ApplicationMailer
  WHITESPACE = ' '.freeze

  layout 'no_signature'
  default to: 'support@hellobar.com',
          from: 'Hello Bar <contact@hellobar.com>'

  def generic_message(message, user, site)
    @message = message
    @website = site&.url
    preview = build_preview(message)

    params = {
      subject: "Contact Form: #{ preview }",
      from: "#{ user.first_name } #{ user.last_name } <#{ user.email }>"
    }

    mail params
  end

  def guest_message(name:, email:, message:)
    preview = build_preview(message)

    params = {
      subject: "Contact Form: #{ preview }",
      from: "#{ name } <#{ email }>"
    }

    mail(params) do |format|
      format.text { render plain: message }
      format.html { render html: message }
    end
  end

  def forgot_email(site_url:, first_name:, last_name:, email:)
    @site_url = site_url
    @email = email
    @name = "#{ first_name } #{ last_name }"

    params = {
      subject: "Customer Support: Forgot Email #{ @name } #{ @email }",
      from: "#{ @name } <#{ @email }>"
    }

    mail params
  end

  def contact_developer(developer_email, site, user)
    @site_url = site.normalized_url
    @script_url = site.script_url
    @user_email = user.email

    params = {
      subject: "Please install Hello Bar on #{ @site_url }",
      to: developer_email
    }

    mail params
  end

  private

  def build_preview(value)
    # removes line-endings and unreadable symbols and truncate message
    value.to_s.gsub(/\s/, WHITESPACE).strip.squeeze(WHITESPACE)[0, 50]
  end
end
