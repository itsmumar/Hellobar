class Subscription
  class ProComped < Subscription
    autoload :Capabilities, 'subscription/pro_comped/capabilities'

    class << self
      def defaults
        {
          type: 'pro_comped',
          name: 'Pro Comped',
          label: 'CMP',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 250_000, # after this many visits in a month
          # visit_overage_amount: 25_000, # every X visitors
          visit_overage_amount: 0.0 # $$$
        }
      end
    end
  end
end
