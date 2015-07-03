class User < ActiveRecord::Base
  include BillingAuditTrail
  include UserValidator

  has_many :payment_methods
  has_many :payment_method_details, through: :payment_methods, source: :details
  has_many :site_memberships
  has_many :sites, through: :site_memberships
  has_many :site_elements, through: :sites
  has_many :authentications, dependent: :destroy
  acts_as_paranoid

  devise :database_authenticatable, :recoverable, :rememberable, :trackable
  # devise :omniauthable, :omniauth_providers => [:google_oauth2]
  delegate :url_helpers, to: "Rails.application.routes"

  validate :email_does_not_exist_in_wordpress, on: :create
  validates :email, uniqueness: {scope: :deleted_at, unless: :deleted? }

  # If we ever assign more than one user to a site, this will have
  # to be refactored
  before_destroy do
    self.sites.each(&:destroy)
  end

  after_save :disconnect_oauth

  attr_accessor :legacy_migration, :timezone

  ACTIVE_STATUS = 'active'
  TEMPORARY_STATUS = 'temporary'
  INVITE_STATUS = 'invited'

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

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil, track_options={})
      data = access_token["info"]
      user = User.joins(:authentications).where(authentications: { uid: access_token["uid"], provider: access_token["provider"] }).first

      unless user
        password = Devise.friendly_token[9,20]
        user = User.new(
          email: data["email"],
          password: password,
          password_confirmation: password
        )
        user.authentications.build(provider: access_token["provider"], uid: access_token["uid"])
        user.save

        Analytics.track(:user, user.id, "Signed Up", track_options) if user.valid?
        Analytics.track(:user, user.id, "Completed Signup", {email: user.email}) if user.valid?
      end

      user.authentications.detect { |x| x.provider == access_token["provider"]}.update(
        refresh_token: access_token["credentials"].refresh_token,
        access_token: access_token["credentials"].token,
        expires_at: Time.at(access_token["credentials"].expires_at)
      ) if access_token["credentials"]

      user
  end

  def self.find_or_invite_by_email(email)
    user = User.where(email: email).first
    if user.nil?
      password = Devise.friendly_token[9,20]
      password_confirmation = password
      user = User.create(
        email: email,
        password: password,
        password_confirmation: password,
        status: INVITE_STATUS
      )
      MailerGateway.send_email("User Invite", email, {:email => email, :reset_link => reset_link})
    end
    user
  end

  private

  # Disconnect oauth logins if user sets their own password
  def disconnect_oauth
    if !id_changed? && encrypted_password_changed? && is_oauth_user?
      authentications.destroy_all
    end
  end

  def email_does_not_exist_in_wordpress
    return if legacy_migration # Don't check this
    errors.add(:email, "has already been taken") if Hello::WordpressUser.email_exists?(email)
  end
end
