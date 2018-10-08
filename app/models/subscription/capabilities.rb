class Subscription::Capabilities
  attr_reader :subscription, :site

  def initialize(subscription, site)
    @subscription = subscription
    @site = site
  end

  def subscription_name
    @subscription.values[:name]
  end

  def acts_as_paid_subscription?
    false
  end

  def remove_branding?
    false
  end

  def closable?
    true
  end

  def custom_targeted_bars?
    false
  end

  def custom_thank_you_text?
    false
  end

  def after_submit_redirect?
    false
  end

  def leading_question?
    false
  end

  def image_opacity?
    false
  end

  def image_overlay_opacity?
    false
  end

  def max_site_elements
    10
  end

  def max_variations
    99999
  end

  def at_site_element_limit?
    @site.site_elements.size >= max_site_elements
  end

  def a_b_test_in_progress?
    @site.site_elements.size >= max_site_elements
  end

  def at_variation_limit? site_element
    @site_element = site_element
    elements_in_group = @site_element.rule.site_elements.select { |se| !se.paused? && se.short_subtype == site_element.short_subtype && se.type == site_element.type }
    elements_in_group.count >= max_variations
  end

  def num_days_improve_data
    90
  end

  def visit_overage
    self.class.parent.defaults[:visit_overage]
  end

  def visit_warning_one
    self.class.parent.defaults[:visit_warning_one]
  end

  def visit_warning_two
    self.class.parent.defaults[:visit_warning_two]
  end

  def visit_warning_three
    self.class.parent.defaults[:visit_warning_three]
  end

  def upsell_email_trigger
    self.class.parent.defaults[:upsell_email_trigger]
  end

  def content_upgrades?
    false
  end

  def autofills?
    false
  end

  def geolocation_injection?
    false
  end

  def external_tracking?
    false
  end

  def alert_bars?
    false
  end

  def advanced_themes?
    false
  end

  def precise_geolocation_targeting?
    false
  end

  def campaigns?
    false
  end

  def disable_script_self_check
    false
  end

  def ==(other)
    self.class == other.class &&
      subscription == other.subscription &&
      site == other.site
  end

  protected

  def parent_class
    self.class.parent
  end
end
