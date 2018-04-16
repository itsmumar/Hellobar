class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url
  attr_accessor :email, :password
  attr_accessor :ignore_existing_site

  attr_reader :user, :site

  validates :site_url, presence: true

  def initialize(params)
    super(params[:registration_form])
    self.site_url ||= params[:site_url]

    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url)
  end

  def existing_site_url?
    return if site_url.blank?

    @existing_site_url ||= Site.by_url(site_url).any?
  end

  def validate!
    user.validate!
    site.validate!
  end
end
