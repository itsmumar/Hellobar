class Subscription::FreePlus::Capabilities < Subscription::Free::Capabilities
  def max_site_elements
    Float::INFINITY
  end
end
