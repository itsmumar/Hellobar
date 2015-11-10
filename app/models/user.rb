class User < ActiveRecord::Base
  include BillingAuditTrail
  include UserValidator

  # Remove any sites where this was the last user
  # This must come before any dependent: :destroy
  before_destroy do
    self.sites.each do |site|
      site.destroy if site.site_memberships.size <= 1
    end
  end

  has_many :payment_methods
  has_many :payment_method_details, through: :payment_methods, source: :details
  has_many :site_memberships, dependent: :destroy
  has_many :sites, through: :site_memberships
  has_many :site_elements, through: :sites
  has_many :authentications, dependent: :destroy
  acts_as_paranoid

  devise :database_authenticatable, :recoverable, :rememberable, :trackable
  # devise :omniauthable, :omniauth_providers => [:google_oauth2]
  delegate :url_helpers, to: "Rails.application.routes"

  validate :email_does_not_exist_in_wordpress, on: :create
  validates :email, uniqueness: {scope: :deleted_at, unless: :deleted? }
  validate :oauth_email_change, if: :is_oauth_user?

  after_save :disconnect_oauth, if: :is_oauth_user?

  before_save do
    if self.status == ACTIVE_STATUS && self.invite_token
      self.invite_token = nil
    end
  end

  attr_accessor :legacy_migration, :timezone

  ACTIVE_STATUS = 'active'
  TEMPORARY_STATUS = 'temporary'
  INVITE_EXPIRE_RATE = 2.week

  # returns a user with a random email and password
  def self.generate_temporary_user
    timestamp = Time.now.to_i

    new_user = User.create email: "hello-#{timestamp}-#{rand(timestamp)}@hellobar.com", password: Digest::SHA1.hexdigest("hello-#{timestamp}-me"), status: TEMPORARY_STATUS

    until new_user.valid?
      generate_temporary_user
    end

    new_user
  end

  # dont require the password virtual attribute to be present
  # if we are migrating users from the legacy DB
  def password_required?
    legacy_migration ? false : super
  end

  def active?
    status == ACTIVE_STATUS
  end

  def temporary_email?
    email.match(/hello\-[0-9]+@hellobar.com/)
  end

  def send_devise_notification(notification, *args)
    host = ActionMailer::Base.default_url_options[:host]

    case notification
    when :reset_password_instructions
      if is_oauth_user?
        reset_link = "#{host}/auth/google_oauth2"
        MailerGateway.send_email("Reset Password Oauth", email, {:email => email, :reset_link => reset_link})
      else
        reset_link = url_helpers.edit_user_password_url(self, :reset_password_token => args[0], :host => host)
        MailerGateway.send_email("Reset Password", email, {:email => email, :reset_link => reset_link})
      end
    end
  end

  def role_for_site(site)
    if membership = site_memberships.where(:site => site).first
      membership.role.to_sym
    else
      nil
    end
  end

  def temporary?
    status == TEMPORARY_STATUS
  end

  after_save :track_temporary_status_change
  def track_temporary_status_change
    if @was_temporary and !temporary?
      Analytics.track(:user, self.id, "Completed Signup", {email: self.email})
      @was_temporary = false
    end
  end

  after_initialize :check_if_temporary
  def check_if_temporary
    @was_temporary = temporary?
  end

  def valid_password?(password)
    Phpass.new.check(password, encrypted_password) || super
  end

  def is_oauth_user?
     authentications.size > 0
  end

  def invite_token_expired?
    invite_token_expire_at && invite_token_expire_at <= Time.now
  end

  def has_permission_for(feature, site)
    role = site.membership_for_user(self).try(:role)
    role && Hellobar::Settings[:permissions][role].try(:include?, feature)
  end

  def name
    first_name || last_name ? "#{first_name} #{last_name}".strip : nil
  end

  def send_invitation_email(site)
    if temporary? && !invite_token_expired?
      send_invite_token_email(site)
    else
      send_team_invite_email(site)
    end
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil, track_options={})
      data = access_token["info"]
      user = User.joins(:authentications).where(authentications: { uid: access_token["uid"], provider: access_token["provider"] }).first

      if user.nil?
        user = User.where(email: data["email"], status: TEMPORARY_STATUS).first
        user ||= User.new(email: data["email"])

        password = Devise.friendly_token[9,20]
        user.password = password
        user.password_confirmation = password

        user.first_name = data["first_name"]
        user.last_name = data["last_name"]

        user.authentications.build(provider: access_token["provider"], uid: access_token["uid"])
        user.status = ACTIVE_STATUS

        user.save

        Analytics.track(:user, user.id, "Signed Up", track_options) if user.valid?
        Analytics.track(:user, user.id, "Completed Signup", {email: user.email}) if user.valid?
      else
        user.first_name = data["first_name"] if data["first_name"].present?
        user.last_name = data["last_name"] if data["last_name"].present?

        user.save
      end

      user.authentications.detect { |x| x.provider == access_token["provider"]}.update(
        refresh_token: access_token["credentials"].refresh_token,
        access_token: access_token["credentials"].token,
        expires_at: Time.at(access_token["credentials"].expires_at)
      ) if access_token["credentials"]

      user
  end

  def self.find_or_invite_by_email(email, site)
    user = User.where(email: email).first

    if user.nil?
      user = User.new(email: email)
      password = Devise.friendly_token[9,20]
      user.password = password
      user.password_confirmation = password
      user.invite_token = Devise.friendly_token
      user.invite_token_expire_at = INVITE_EXPIRE_RATE.from_now
      user.status = TEMPORARY_STATUS
      user.save
    end

    user
  end

  def self.search_by_url(url)
    host = Site.normalize_url(url).host
    if host
      domain = PublicSuffix.parse(host).domain
      User.joins(:sites).where("url like ?", "%#{domain}%")
    else
      User.none
    end
  rescue Addressable::URI::InvalidURIError
    User.none
  end

  def self.search_by_username(username)
    User.with_deleted.where("email like ?", "%#{username}%")
  end

  private

  def send_team_invite_email(site)
    host = ActionMailer::Base.default_url_options[:host]
    login_link = is_oauth_user? ? "#{host}/auth/google_oauth2" : url_helpers.new_user_session_url(host: host)
    MailerGateway.send_email("Team Invite", email, {site_url: site.url, login_url: login_link})
  end

  def send_invite_token_email(site)
    host = ActionMailer::Base.default_url_options[:host]
    oauth_link = "#{host}/auth/google_oauth2"
    signup_link = url_helpers.invite_user_url(invite_token: invite_token, :host => host)
    MailerGateway.send_email("Invitation", email, {site_url: site.url, oauth_link: oauth_link, signup_link: signup_link})
  end

  # Disconnect oauth logins if user sets their own password
  def disconnect_oauth
    if !id_changed? && encrypted_password_changed? && is_oauth_user?
      authentications.destroy_all
    end
  end

  def oauth_email_change
    if !id_changed? && is_oauth_user? && email_changed? && !encrypted_password_changed?
      errors.add(:email, "cannot be changed without a password.")
    end
  end

  def email_does_not_exist_in_wordpress
    return if legacy_migration # Don't check this
    errors.add(:email, "has already been taken") if Hello::WordpressUser.email_exists?(email)
  end
end
