class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url
  attr_accessor :email, :password
  attr_reader :accept_terms_and_conditions, :ignore_existing_site

  attr_reader :user, :site

  def initialize(params)
    super(params[:registration_form])

    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url)
  end

  def ignore_existing_site=(value)
    @ignore_existing_site = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def accept_terms_and_conditions=(value)
    @accept_terms_and_conditions = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def existing_site_url?
    return false unless site.valid?

    self.ignore_existing_site = true

    @existing_site_url ||= Site.by_url(site.url).any?
  end

  def validate!
    user.validate!
    site.validate!
  end
end
