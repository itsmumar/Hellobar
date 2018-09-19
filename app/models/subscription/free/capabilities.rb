class Subscription::Free::Capabilities < Subscription::Capabilities
  def max_variations
    3
  end

  def max_a_b_tests
    1
  end
end
