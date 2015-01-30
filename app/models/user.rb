class User < ActiveRecord::Base
  include BillingAuditTrail
  has_many :payment_methods
  has_many :payment_method_details, through: :payment_methods, source: :details
  has_many :site_memberships
  has_many :sites, through: :site_memberships
  acts_as_paranoid

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  delegate :url_helpers, to: "Rails.application.routes"

  validate :email_does_not_exist_in_wordpress, on: :create
  validates :email, uniqueness: true

  # If we ever assign more than one user to a site, this will have
  # to be refactored
  before_destroy do
    self.sites.each(&:destroy)
  end

  attr_accessor :legacy_migration, :timezone

  ACTIVE_STATUS = 'active'
  TEMPORARY_STATUS = 'temporary'

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
      reset_link = url_helpers.edit_user_password_url(self, :reset_password_token => args[0], :host => host)
      MailerGateway.send_email("Reset Password", email, {:email => email, :reset_link => reset_link})
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


  private

  def email_does_not_exist_in_wordpress
    return if legacy_migration # Don't check this
    errors.add(:email, "has already been taken") if Hello::WordpressUser.email_exists?(email)
  end
end
