class Users::ForgotEmailsController < ApplicationController
  layout 'static'

  def new
  end

  def create
    MailerGateway.send_email('Forgot Email', 'support@hellobar.com', forgot_email_params)

    redirect_to new_forgot_email_path, notice: "We'll get in touch with you shortly!"
  end

private

  def forgot_email_params
    params.permit(:site_url, :first_name, :last_name, :email)
  end
end
