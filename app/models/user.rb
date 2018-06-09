class User < ApplicationRecord
  NEW_TERMS_AND_CONDITIONS_EFFECTIVE_DATE = Date.new(2018, 4, 26)

  acts_as_paranoid

  include UserValidator

  devise :database_authenticatable, :recoverable, :rememberable, :trackable
  # devise :omniauthable, :omniauth_providers => [:google_oauth2]

  before_save :clear_invite_token
  after_save :disconnect_oauth, if: :oauth_user?
  after_create :create_referral_token

  has_one :referral_token, as: :tokenizable, dependent: :destroy, inverse_of: :tokenizable
  has_one :affiliate_information

  has_many :credit_cards, dependent: :destroy
  has_many :site_memberships, dependent: :destroy
  has_many :sites, -> { distinct }, through: :site_memberships
  has_many :site_elements, through: :sites
  has_many :contact_lists, through: :sites
  has_many :subscriptions, through: :sites
  has_many :authentications, dependent: :destroy

  has_one :received_referral, class_name: 'Referral', foreign_key: 'recipient_id',
    dependent: :destroy, inverse_of: :recipient

  has_many :sent_referrals, class_name: 'Referral',
    foreign_key: 'sender_id', dependent: :destroy, inverse_of: :sender

  scope :wordpress_users, -> { where.not(wordpress_user_id: nil) }

  validates :email, uniqueness: { scope: :deleted_at, unless: :deleted? }
  validate :oauth_email_change, if: :oauth_user?

  delegate :url_helpers, to: 'Rails.application.routes'

  attr_accessor :timezone, :is_impersonated

  ACTIVE = 'active'.freeze
  TEMPORARY = 'temporary'.freeze
  DELETED = 'deleted'.freeze
  INVITE_EXPIRE_RATE = 2.weeks

  def can_view_exit_intent_modal?
    user_upgrade_policy.should_show_exit_intent_modal?
  end

  def can_view_upgrade_suggest_modal?
    user_upgrade_policy.should_show_upgrade_suggest_modal?
  end

  def most_viewed_site_element
    site_elements.sort_by(&:total_views).last
  end

  def most_viewed_site_element_subtype
    subtype = most_viewed_site_element.try(:element_subtype)
    subtype = 'social' if subtype&.include?('social')
    subtype
  end

  def new?
    sign_in_count == 1 && site_elements.empty?
  end

  def pro_managed?
    sites.any?(&:pro_managed?)
  end

  def active?
    status == ACTIVE
  end

  def temporary?
    status == TEMPORARY
  end

  def temporary_email?
    email.match(/hello\-[0-9]+@hellobar.com/)
  end

  def paying_subscription?
    subscriptions.paid.any? do |subscription|
      subscription.capabilities.acts_as_paid_subscription?
    end
  end

  def send_devise_notification(notification, reset_password_token = nil, *_args)
    case notification
    when :reset_password_instructions
      PasswordMailer.reset(self, reset_password_token).deliver_later
    end
  end

  def role_for_site(site)
    return unless (membership = site_memberships.find_by(site: site))
    membership.role.to_sym
  end

  def valid_password?(password)
    Phpass.new.check(password, encrypted_password) || super
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def oauth_user?
    !authentications.empty?
  end

  def invite_token_expired?
    invite_token_expire_at && invite_token_expire_at <= Time.current
  end

  def name
    first_name || last_name ? "#{ first_name } #{ last_name }".strip : nil
  end

  def self.find_or_invite_by_email(email, _site)
    user = User.find_by(email: email)

    if user.nil?
      user = User.new(email: email)
      password = Devise.friendly_token[9, 20]
      user.password = password
      user.password_confirmation = password
      user.invite_token = Devise.friendly_token
      user.invite_token_expire_at = INVITE_EXPIRE_RATE.from_now
      user.status = TEMPORARY
      user.save
    end

    user
  end

  def self.search_by_site_url url
    domain = NormalizeURI[url]&.domain
    if domain
      where(
        id: SiteMembership.with_deleted.joins(:site).where('url LIKE ?', "%#{ domain }%").select(:user_id)
      )
    else
      none
    end
  end

  def self.search_by_username(username)
    with_deleted.where('email like ?', "%#{ username }%")
  end

  def was_referred?
    received_referral.present?
  end

  private

  def user_upgrade_policy
    @user_upgrade_policy ||= ::UserUpgradePolicy.new(self, paying_subscription?)
  end

  # Disconnect oauth logins if user sets their own password
  def disconnect_oauth
    return unless !id_changed? && encrypted_password_changed? && oauth_user?
    authentications.destroy_all
  end

  def clear_invite_token
    self.invite_token = nil if active? && invite_token
  end

  def oauth_email_change
    return unless !id_changed? && oauth_user? && email_changed? && !encrypted_password_changed?
    errors.add(:email, 'cannot be changed without a password.')
  end
end
