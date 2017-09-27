class Subscription
  class ProManaged < Subscription
    class Capabilities < Pro::Capabilities
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

      def opacity?
        true
      end

      def advanced_themes?
        true
      end

      def precise_geolocation_targeting?
        true
      end
    end

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
