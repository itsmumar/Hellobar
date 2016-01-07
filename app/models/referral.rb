class Referral < ActiveRecord::Base
  include ReferralTokenizable
  STATES = {
    'sent' => 'Invite sent',
    'signed_up' => 'Signed up',
    'installed' => 'Installed'
  }

  EXPIRES_INTERVAL = 5.days
  scope :about_to_expire, -> do
    where(state: 'sent').where(created_at: (EXPIRES_INTERVAL.ago .. (EXPIRES_INTERVAL - 1.day).ago))
  end

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  has_one :referral_token, as: :tokenizable

  validates :state, inclusion: STATES.keys
  validates :sender_id, presence: true
  validates :email, presence: true
  validate :email_not_already_registered, on: :create

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: sender.name)
  end


  def url
    return "" if referral_token.blank?

    path = Rails.application.routes.url_helpers.accept_referrals_path(token: referral_token.token)
    Hellobar::Settings[:url_base] + path
  end

  def expiration_date_string
    expiration_date = (created_at + EXPIRES_INTERVAL)
    expiration_date_string = expiration_date.strftime("%B ") + expiration_date.day.ordinalize
  end

  def accepted?
    state != 'sent'
  end

  private

  def email_not_already_registered
    return if email.blank?
    return if recipient # If we're creating with a recipient, we don't need to run this check at all

    if User.where(email: email).count > 0
      errors.add(:email, "belongs to a user who's already registered.")
    end
  end
end
