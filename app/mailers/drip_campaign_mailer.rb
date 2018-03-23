class DripCampaignMailer < ApplicationMailer
  layout 'user_mailer'
  default from: 'Hello Bar <contact@hellobar.com>',
          subject: 'Note from Hello Bar support'

  helper_method :greeting

  def create_a_bar(user)
    @user = user
    mail to: user.email
  end

  # TODO: remove this email
  def configure_your_bar(user)
    @user = user
    mail to: user.email
  end

  private

  def greeting
    @user.first_name.present? ? "Hi #{ @user.first_name }," : 'Hello,'
  end
end
