class User < ActiveRecord::Base
  has_many :site_memberships
  has_many :sites, :through => :site_memberships

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  delegate :url_helpers, to: "Rails.application.routes"

  validate :uniqueness_of_email

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

  private

  def uniqueness_of_email
    email_does_not_exist_in_wordpress

    errors.add(:email, 'has already been taken') if User.exists?(email: email)
  end

  def email_does_not_exist_in_wordpress
    errors.add(:email, "has already been taken") if Hello::WordpressUser.email_exists?(email)
  end
end
