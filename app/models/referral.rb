class Referral < ActiveRecord::Base
  include ReferralTokenizable

  FOLLOWUP_INTERVAL = 5.days

  enum state: [:sent, :signed_up, :installed]

  scope :redeemable_by_user, ->(user) do
    installed.where(
      '(redeemed_by_recipient_at IS NULL AND recipient_id = :user_id) OR (sender_id = :user_id AND available_to_sender = true)',
      user_id: user.id
    )
  end

  scope :to_be_followed_up, -> do
    sent.where(created_at: (FOLLOWUP_INTERVAL.ago .. (FOLLOWUP_INTERVAL - 1.day).ago))
  end

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :site

  has_one :referral_token, as: :tokenizable

  validates :sender_id, presence: true
  validates :email, presence: true
  validate :ensure_email_available, on: :create

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: sender.name)
  end

  def set_site_if_only_one
    return if site_id.present?
    if sender.sites.count == 1
      self.site = sender.sites.first
    end
  end

  def url
    return "" if referral_token.blank?

    Rails.application.routes.url_helpers.accept_referrals_url(
      token: referral_token.token,
      host: Hellobar::Settings[:host]
    )
  end

  def expiration_date_string
    expiration_date = (created_at + FOLLOWUP_INTERVAL)
    expiration_date_string = expiration_date.strftime("%B ") + expiration_date.day.ordinalize
  end

  def accepted?
    state != 'sent'
  end

  def redeemable_by_sender?
    state == 'installed' && available_to_sender == true && redeemed_by_sender_at == nil
  end

  def redeemed_by_sender?
    state == 'installed' && available_to_sender == false && redeemed_by_sender_at != nil
  end

  def email_already_registered?
    return false if email.blank?
    User.where(email: email).count > 0
  end

  def email_already_referrred?
    return false if email.blank?
    Referral.where(email: email).count > 0
  end

  private

  def ensure_email_available
    return if email.blank?
    return if recipient # If we're creating with a recipient, we don't need to run this check at all

    if User.where(email: email).count > 0
      errors.add(:email, "belongs to a user who's already registered.")
    elsif sender.sent_referrals.where(email: email).count > 0
      errors.add(:email, "belongs to a user you've already invited..")
    end
  end
end
