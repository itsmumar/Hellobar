class Subscription::ProManaged::Capabilities < Subscription::Pro::Capabilities
  def content_upgrades?
    true
  end

  def autofills?
    true
  end

  def geolocation_injection?
    true
  end

  def external_tracking?
    true
  end

  def alert_bars?
    true
  end

  def campaigns?
    true
  end

  def disable_script_self_check
    true
  end
end
