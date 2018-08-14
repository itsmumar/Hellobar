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
          visit_overage: 25_000,
          visit_overage_amount: nil # ads
        }
      end
    end
  end
end
