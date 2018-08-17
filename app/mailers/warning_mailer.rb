class WarningMailer < ApplicationMailer

  def warning_email
    @plan = params[:plan]
    @user = params[:user]
    @site  = params[:site]
    mail(to: @user.email, subject: "You're approaching your Hello Bar monthly view limit!")
  end
end
