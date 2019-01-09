class RegistrationForm
  include ActiveModel::Model

  attr_accessor :site_url, :email, :password, :plan
  attr_reader :accept_terms_and_conditions, :ignore_existing_site

  attr_reader :user, :site

  def initialize(params, cookies = {})
    super(params[:registration_form])
    @user = User.new(email: email, password: password)
    @site = Site.new(url: site_url, pre_selected_plan: plan)
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
    return neil_title if neil_signup?
    return dollar_trial if dollar_signup?
    return default_title unless promotional_signup? || affiliate_signup? || paid_signup?
    return paid_title if paid_signup? && !neil_signup? && !dollar_signup?
    return promotional_signup_title unless affiliate_signup?
    return affiliate_signup_title unless partner?

    partner_signup_title
  end

  def cta
    return neil_cta if neil_signup?
    return dollar_cta if dollar_signup?
    return default_cta unless promotional_signup? || affiliate_signup? || paid_signup?
    return promotional_signup_cta unless affiliate_signup? || paid_signup?
    return affiliate_signup_cta unless partner? || paid_signup?
    return paid_signup_cta if paid_signup?

    partner_signup_cta
  end

  private

  def default_title
    I18n.t :default_title, scope: :registration
  end
  alias default_cta default_title

  def paid_title
    I18n.t :paid_title, scope: :registration
  end

  def neil_title
    I18n.t :neil_title, scope: :registration
  end

  def dollar_trial
    I18n.t :dollar_trial_name, scope: :registration
  end

  def promotional_signup_title
    duration = PromotionalPlan.new.duration
    subscription = PromotionalPlan.new.subscription_type.capitalize

    I18n.t :promotional_signup_title, scope: :registration,
      duration: duration, subscription: subscription
  end

  def promotional_signup_cta
    duration = PromotionalPlan.new.duration

    I18n.t :promotional_signup_cta, scope: :registration, duration: duration
  end

  def paid_signup_cta
    duration = PromotionalPlan.new.duration

    I18n.t :paid_cta, scope: :registration, duration: duration
  end

  def neil_cta
    I18n.t :neil_cta, scope: :registration
  end

  def dollar_cta
    I18n.t :dollar_cta, scope: :registration
  end

  def affiliate_signup_title
    duration = default_partner_plan.duration
    subscription = default_partner_plan.subscription_type.capitalize

    I18n.t :affiliate_signup_title, scope: :registration,
      duration: duration, subscription: subscription
  end

  def affiliate_signup_cta
    duration = default_partner_plan.duration

    I18n.t :affiliate_signup_cta, scope: :registration, duration: duration
  end

  def partner_signup_title
    community = @partner.community
    duration = @partner.partner_plan.duration
    subscription = @partner.partner_plan.subscription_type.capitalize

    I18n.t :partner_signup_title, scope: :registration, duration: duration,
      community: community, subscription: subscription
  end

  def partner_signup_cta
    duration = @partner.partner_plan.duration

    I18n.t :partner_signup_cta, scope: :registration, duration: duration
  end

  def paid_signup?
    @cookies[:the_plan] == 'paid'
  end

  def neil_signup?
    @cookies[:neil_signup] == 'true'
  end

  def dollar_signup?
    @cookies[:dollar_trial] == 'true'
  end

  def promotional_signup?
    @cookies[:promotional_signup] == 'true'
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

  def default_partner_plan
    Partner.default_partner_plan
  end
end
