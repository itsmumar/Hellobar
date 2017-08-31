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

  has_one :referral_token, as: :tokenizable
  has_many :credit_cards
  has_many :site_memberships, dependent: :destroy
  has_many :sites, -> { distinct }, through: :site_memberships
  has_many :site_elements, through: :sites
  has_many :contact_lists, through: :sites
  has_many :subscriptions, through: :sites
  has_many :authentications, dependent: :destroy
  has_many :sent_referrals, dependent: :destroy, class_name: 'Referral', foreign_key: 'sender_id'
  has_one :received_referral, class_name: 'Referral', foreign_key: 'recipient_id'
  has_many :onboarding_statuses, -> { order(created_at: :desc, id: :desc) }, class_name: 'UserOnboardingStatus'
  has_one :current_onboarding_status, -> { order 'created_at DESC' }, class_name: 'UserOnboardingStatus'

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

  ACTIVE_STATUS = 'active'.freeze
  TEMPORARY_STATUS = 'temporary'.freeze
  INVITE_EXPIRE_RATE = 2.weeks

  def self.search_all_versions_for_email(email)
    return if email.blank?

    find_by_email(email) || find_and_create_by_referral(email)
  end

  def self.find_and_create_by_referral(email)
    return unless Referral.find_by(email: email)
    password = Devise.friendly_token[9, 20]

    User.create email: email,
                status: TEMPORARY_STATUS,
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
    subtype = 'social' if subtype && subtype.include?('social')
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
    status == ACTIVE_STATUS
  end

  def temporary?
    status == TEMPORARY_STATUS
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

  def self.find_for_google_oauth2(omniauth_hash, original_email = nil, track_options = {})
    info = omniauth_hash.info

    if original_email.present? && info.email != original_email # the user is trying to login with a different Google account
      user = User.new
      user.errors.add(:base, "Please log in with your #{ original_email } Google email")
      raise ActiveRecord::RecordInvalid, user
    elsif (user = User.joins(:authentications).find_by(authentications: { uid: omniauth_hash.uid, provider: omniauth_hash.provider }))
      # TODO: deprecated case. use #update_authentication directly
      user.first_name = info.first_name if info.first_name.present?
      user.last_name = info.last_name if info.last_name.present?

      user.save
    else # create a new user
      user = User.find_by(email: info.email, status: TEMPORARY_STATUS) || User.new(email: info.email)

      password = Devise.friendly_token[9, 20]
      user.password = password
      user.password_confirmation = password

      user.first_name = info.first_name
      user.last_name = info.last_name

      user.authentications.build(provider: omniauth_hash.provider, uid: omniauth_hash.uid)
      user.status = ACTIVE_STATUS

      if user.save
        TrackEvent.new(:signed_up, user: user).call

        Analytics.track(:user, user.id, 'Signed Up', track_options)
        Analytics.track(:user, user.id, 'Completed Signup', email: user.email)
      end
    end

    # TODO: deprecated. use #update_authentication directly
    # update the authentication tokens & expires for this provider
    if omniauth_hash.credentials && user.persisted?
      user.authentications.detect { |x| x.provider == omniauth_hash.provider }.update(
        refresh_token: omniauth_hash.credentials.refresh_token,
        access_token: omniauth_hash.credentials.token,
        expires_at: Time.zone.at(omniauth_hash.credentials.expires_at)
      )
    end

    user
  end

  def update_authentication(omniauth_hash)
    authentication = authentications.find_by(uid: omniauth_hash.uid, provider: omniauth_hash.provider)

    self.first_name = omniauth_hash.info.first_name if omniauth_hash.info.first_name.present?
    self.last_name = omniauth_hash.info.last_name if omniauth_hash.info.last_name.present?

    if omniauth_hash.credentials && persisted?
      authentication.update(
        refresh_token: omniauth_hash.credentials.refresh_token,
        access_token: omniauth_hash.credentials.token,
        expires_at: Time.zone.at(omniauth_hash.credentials.expires_at)
      )
    end

    save!
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
      user.status = TEMPORARY_STATUS
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
