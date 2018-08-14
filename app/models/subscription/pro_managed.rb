class Subscription
  class ProManaged < Subscription
    autoload :Capabilities, 'subscription/pro_managed/capabilities'

    class << self
      def defaults
        {
          type: 'pro_managed',
          name: 'Pro Managed',
          label: 'MNG',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: ::Float::INFINITY, # after this many visits in a month
          visit_overage_amount: nil # $$$
        }
      end
    end
  end
end
