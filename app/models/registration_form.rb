class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url
  attr_accessor :email, :password
  attr_reader :ignore_existing_site

  attr_reader :user, :site

  validates :site_url, presence: true, url: true

  def initialize(params)
    super(params[:registration_form])

    self.site_url ||= standardize_url(params[:site_url])

    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url)
  end

  def ignore_existing_site=(value)
    @ignore_existing_site = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def existing_site_url?
    return false unless site.valid?

    @existing_site_url ||= Site.by_url(site.url).any?
  end

  def validate!
    user.validate!
    site.validate!
  end

  private

  def standardize_url(url)
    return if url.blank?
    parsed_url = Addressable::URI.heuristic_parse(url)
    "#{ parsed_url.scheme }://#{ parsed_url.normalized_host }"
  rescue Addressable::URI::InvalidURIError
    nil
  end
end
