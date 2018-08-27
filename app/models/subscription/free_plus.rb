class Subscription
  class FreePlus < Free
    autoload :Capabilities, 'subscription/free_plus/capabilities'

    class << self
      def defaults
        {
          type: 'free_plus',
          name: 'Free Plus',
          label: 'FREE',
          monthly_amount: 0.0,
          yearly_amount: 0.0,
          visit_warning_one: 2500,
          visit_warning_two: 4000,
          visit_warning_three: 4500,
          visit_overage: 5000,
          visit_overage_amount: nil # ads
        }
      end
    end
  end
end
