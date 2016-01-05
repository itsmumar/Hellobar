class Referral < ActiveRecord::Base
  include ReferralTokenizable
  STATES = {
    'sent' => 'Invite sent',
    'signed_up' => 'Signed up',
    'installed' => 'Installed'
  }

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  has_one :referral_token, as: :tokenizable

  validates :state, inclusion: STATES.keys
  validates :sender_id, presence: true
  validates :email, presence: true
  validate :email_not_already_registered, on: :create
  after_create :send_invitation_email

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: sender.name)
  end

  private

  def email_not_already_registered
    return if email.blank?
    return if recipient && recipient.temporary? # No need to check in this case

    if User.where(email: email).count > 0
      errors.add(:email, "belongs to a user who's already registered.")
    end
  end

  def referral_link
    path = Rails.application.routes.url_helpers.accept_referrals_path(token: referral_token.token)
    Hellobar::Settings[:url_base] + path
  end

  def send_invitation_email
    expiration_date = (created_at + 2.weeks)
    expiration_date_string = expiration_date.strftime("%B ") + expiration_date.day.ordinalize
    MailerGateway.send_email("Referal Invite Initial", email, {
      referral_sender: sender.email,
      referral_expiration_date: expiration_date_string,
      referral_body: body,
      referral_link: referral_link
    })
  end
end
