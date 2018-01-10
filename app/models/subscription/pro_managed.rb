class Subscription
  class ProManaged < Subscription
    autoload :Capabilities, 'subscription/free_plus/capabilities'

    class << self
      def defaults
        {
          name: 'Pro Managed',
          label: 'MNG',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: nil, # after this many visits in a month
          # visit_overage_amount: 25_000, # every X visitors
          visit_overage_amount: nil # $$$
        }
      end
    end
  end
end
