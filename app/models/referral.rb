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
  validate :email_not_already_registered, on: :create

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: sender.name)
  end

  def set_site_if_only_one
    if sender.sites.count == 1
      self.site = sender.sites.first
    end
  end

  def url
    return "" if referral_token.blank?

    path = Rails.application.routes.url_helpers.accept_referrals_path(token: referral_token.token)
    Hellobar::Settings[:url_base] + path
  end

  def expiration_date_string
    expiration_date = (created_at + FOLLOWUP_INTERVAL)
    expiration_date_string = expiration_date.strftime("%B ") + expiration_date.day.ordinalize
  end

  def accepted?
    state != 'sent'
  end

  def redeemable?
    state == 'installed' && available_to_sender == true && redeemed_by_sender_at == nil
  end

  def redeemed?
    state == 'installed' && available_to_sender == false && redeemed_by_sender_at != nil
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
