class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url
  attr_accessor :email, :password
  attr_reader :user, :site

  validates :site_url, presence: true

  def initialize(params)
    super(params[:registration_form])
    self.site_url ||= params[:site_url]

    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url)
  end
end
