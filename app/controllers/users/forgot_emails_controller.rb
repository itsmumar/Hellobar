class Users::ForgotEmailsController < ApplicationController
  layout 'static'

  def new
  end

  def create
    MailerGateway.send_email("User Forgot Email", "support@hellobar.com", params)

    redirect_to new_forgot_email_path, notice: "We'll get in touch with you shortly!"
  end
end
