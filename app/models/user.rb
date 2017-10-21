class User < ActiveRecord::Base
  acts_as_paranoid

  include UserValidator

  devise :database_authenticatable, :recoverable, :rememberable, :trackable
  # devise :omniauthable, :omniauth_providers => [:google_oauth2]

  after_initialize :check_if_temporary
  before_save :clear_invite_token
  after_save :disconnect_oauth, if: :oauth_user?
  after_save :track_temporary_status_change
  after_create :create_referral_token
  after_create :add_to_onboarding_campaign

  # rubocop: disable Rails/HasManyOrHasOneDependent
  has_one :referral_token, as: :tokenizable, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :site_memberships, dependent: :destroy
  has_many :sites, -> { distinct }, through: :site_memberships
  has_many :site_elements, through: :sites
  has_many :contact_lists, through: :sites
  has_many :subscriptions, through: :sites
  has_many :authentications, dependent: :destroy

  has_one :received_referral, class_name: 'Referral', foreign_key: 'recipient_id',
    dependent: :destroy

  has_many :sent_referrals, class_name: 'Referral',
    foreign_key: 'sender_id', dependent: :destroy

  has_many :onboarding_statuses, -> { order(created_at: :desc, id: :desc) },
    class_name: 'UserOnboardingStatus', dependent: :destroy

  has_one :current_onboarding_status, -> { order 'created_at DESC' },
    class_name: 'UserOnboardingStatus'

  scope :join_current_onboarding_status, lambda {
    joins(:onboarding_statuses)
      .where("user_onboarding_statuses.created_at =
              (SELECT MAX(user_onboarding_statuses.created_at)
                      FROM user_onboarding_statuses
                      WHERE user_onboarding_statuses.user_id = users.id)")
      .group('users.id')
  }

  scope :onboarding_sequence_before, lambda { |sequence_index|
    where("user_onboarding_statuses.sequence_delivered_last < #{ sequence_index } OR
           user_onboarding_statuses.sequence_delivered_last IS NULL")
  }

  scope :wordpress_users, -> { where.not(wordpress_user_id: nil) }

  validates :email, uniqueness: { scope: :deleted_at, unless: :deleted? }
  validate :oauth_email_change, if: :oauth_user?

  delegate :url_helpers, to: 'Rails.application.routes'

  attr_accessor :timezone, :is_impersonated

  ACTIVE = 'active'.freeze
  TEMPORARY = 'temporary'.freeze
  DELETED = 'deleted'.freeze
  INVITE_EXPIRE_RATE = 2.weeks

  def self.search_all_versions_for_email(email)
    return if email.blank?

    find_by(email: email) || find_and_create_by_referral(email)
  end

  def self.find_and_create_by_referral(email)
    return unless Referral.find_by(email: email)
    password = Devise.friendly_token[9, 20]

    User.create email: email,
                status: TEMPORARY,
                password: password, password_confirmation: password
  end

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

  def should_send_to_new_site_element_path?
    return false unless current_onboarding_status

    %i[new selected_goal].include?(current_onboarding_status.status_name) &&
      sites.script_not_installed.any?
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
    subscriptions.active.any? { |subscription| subscription.capabilities.acts_as_paid_subscription? }
  end

  def onboarding_status_setter
    @onboarding_status_setter ||= UserOnboardingStatusSetter.new(self, paying_subscription?, onboarding_statuses)
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

  def track_temporary_status_change
    return unless @was_temporary && !temporary?
    Analytics.track(:user, id, 'Completed Signup', email: email)
    @was_temporary = false
  end

  def check_if_temporary
    @was_temporary = temporary?
  end

  def add_to_onboarding_campaign
    onboarding_status_setter.new_user!
    onboarding_status_setter.created_site!
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
    domain ? User.joins(:sites).where('url LIKE ?', "%#{ domain }%") : User.none
  end

  def self.search_by_username(username)
    User.with_deleted.where('email like ?', "%#{ username }%")
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
