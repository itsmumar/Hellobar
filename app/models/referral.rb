class Referral < ApplicationRecord
  FOLLOWUP_INTERVAL = 5.days

  SENT = 'sent'.freeze
  SIGNED_UP = 'signed_up'.freeze
  INSTALLED = 'installed'.freeze
  STATES = [SENT, SIGNED_UP, INSTALLED].freeze

  scope :redeemable_by_sender_for_site, ->(site) { installed.where(available_to_sender: true, site_id: site.id) }
  scope :to_be_followed_up, -> { sent.where(created_at: (FOLLOWUP_INTERVAL.ago..(FOLLOWUP_INTERVAL - 1.day).ago)) }

  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  belongs_to :site

  has_one :referral_token, as: :tokenizable, dependent: :destroy

  validates :sender_id, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }
  validate :ensure_email_available, on: :create

  after_create :create_referral_token

  STATES.each do |state|
    # define .sent .signed_up .installed
    scope state, -> { where(state: state) }

    # define #sent? #signed_up? #installed?
    define_method state + '?' do
      self.state == state
    end
  end

  def self.redeemable_for_site(site)
    possible_recipient_ids = site.owners.pluck(:id)
    installed.where('
      (redeemed_by_recipient_at IS NULL AND recipient_id IN (?))
      OR (available_to_sender = true AND site_id = ?)
    ', possible_recipient_ids, site.id)
  end

  def set_standard_body
    self.body = I18n.t('referral.standard_body', name: sender.name)
  end

  def set_site_if_only_one
    return if site_id.present?
    self.site = sender.sites.first if sender.sites.count == 1
  end

  def url
    return '' if referral_token.blank?

    Rails.application.routes.url_helpers.accept_referrals_url(
      token: referral_token.token,
      host: Settings.host
    )
  end

  def expiration_date_string
    expiration_date = (created_at + FOLLOWUP_INTERVAL)
    expiration_date.strftime('%B ') + expiration_date.day.ordinalize
  end

  def already_accepted?
    installed? || redeemed_by_recipient_at?
  end

  def accepted?
    state != SENT
  end

  def redeemable_by_sender?
    state == INSTALLED && available_to_sender == true && redeemed_by_sender_at.blank?
  end

  def redeemed_by_sender?
    state == INSTALLED && available_to_sender == false && redeemed_by_sender_at.present?
  end

  private

  def ensure_email_available
    return if recipient # If we're creating with a recipient, we don't need to run this check at all

    if User.where(email: email).count > 0
      errors.add(:email, "belongs to a user who's already registered.")
    elsif sender.sent_referrals.where(email: email).count > 0
      errors.add(:email, "belongs to a user you've already invited..")
    end
  end
end
