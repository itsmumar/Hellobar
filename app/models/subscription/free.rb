class Subscription
  class Free < Subscription
    autoload :Capabilities, 'subscription/free/capabilities'

    def free?
      true
    end

    class << self
      def defaults
        {
          type: 'free',
          name: 'Free',
          label: 'FREE',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_overage: 5000, # after this many visits in a month
          visit_overage_amount: nil, # ads
          visit_warning_one: 2500,
          visit_warning_two: 4000,
          visit_warning_three: 4500,
          upsell_email_trigger: ::Float::INFINITY,
          upgrade_trigger: ::Float::INFINITY
        }
      end
    end
  end
end
