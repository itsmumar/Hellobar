class Subscription
  class ProManaged < Pro
    class Capabilities < Pro::Capabilities
      def subtle_facet_theme?
        true
      end

      def custom_html?
        true
      end

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
    end

    class << self
      def defaults
        {
          name: 'Pro Managed',
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
