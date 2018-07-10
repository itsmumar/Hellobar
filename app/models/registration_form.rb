class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url
  attr_accessor :email, :password
  attr_reader :accept_terms_and_conditions, :ignore_existing_site

  attr_reader :user, :site

  def initialize(params, cookies = {})
    super(params[:registration_form])

    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url)
    @cookies = cookies
  end

  def ignore_existing_site=(value)
    @ignore_existing_site = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def accept_terms_and_conditions=(value)
    @accept_terms_and_conditions = ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
  end

  def existing_site_url?
    return false unless site.valid?

    @existing_site_url ||= Site.by_url(site.url).any?
  end

  def validate!
    user.validate!
    site.validate!
  end

  def title
    return default_title unless affiliate_signup?
    return affiliate_trial_signup_title unless partner?

    partner_signup_title
  end

  def cta
    return default_cta unless affiliate_signup?
    return affiliate_trial_signup_cta unless partner?

    partner_signup_cta
  end

  private

  def default_title
    I18n.t :default_title, scope: :registration
  end
  alias default_cta default_title

  def affiliate_trial_signup_title
    I18n.t :affiliate_trial_signup_title, scope: :registration
  end

  def affiliate_trial_signup_cta
    I18n.t :affiliate_trial_signup_cta, scope: :registration
  end

  def partner_signup_title
    community = @partner.community
    duration = @partner.partner_plan.duration

    I18n.t :partner_signup_title, scope: :registration, duration: duration, community: community
  end

  def partner_signup_cta
    duration = @partner.partner_plan.duration

    I18n.t :partner_signup_cta, scope: :registration, duration: duration
  end

  def affiliate_signup?
    affiliate_identifier.present? && visitor_identifier.present?
  end

  def partner?
    return if affiliate_identifier.blank?

    @partner ||= Partner.find_by affiliate_identifier: affiliate_identifier
  end

  def affiliate_identifier
    @cookies[:tap_aid]
  end

  def visitor_identifier
    @cookies[:tap_vid]
  end
end
