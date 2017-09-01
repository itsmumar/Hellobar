class DripCampaignMailer < ApplicationMailer
  default from: 'Hello Bar <contact@hellobar.com>',
    subject: 'Note from Hello Bar support'

  helper_method :greeting

  def create_a_bar(user)
    @user = user
    mail to: user.email
  end

  def configure_your_bar(user)
    mail to: user.email
  end

  private

  def greeting
    @user.first_name.present? ? "Hi #{ @user.first_name }," : 'Hello,'
  end
end
