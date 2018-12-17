class Subscription::Enterprise::Capabilities < Subscription::Pro::Capabilities
  def advanced_themes?
    true
  end
end
