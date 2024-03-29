class Subscription::Pro::Capabilities < Subscription::Free::Capabilities
  def acts_as_paid_subscription?
    true
  end

  def remove_branding?
    true
  end

  def closable?
    true
  end

  def custom_targeted_bars?
    true
  end

  def custom_thank_you_text?
    true
  end

  def after_submit_redirect?
    true
  end

  def leading_question?
    true
  end

  def image_opacity?
    true
  end

  def image_overlay_opacity?
    true
  end

  def activate_on_exit?
    true
  end

  def precise_geolocation_targeting?
    true
  end

  def max_site_elements
    99999
  end

  def num_days_improve_data
    180
  end

  def max_variations
    99999
  end

  def max_a_b_tests
    99999
  end

  def advanced_themes?
    true
  end
end
