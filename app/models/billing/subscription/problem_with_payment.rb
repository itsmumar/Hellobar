class Subscription
  # These are the capabilities of a user who has an issue with payment
  # They are basically the same as Free, but we don't let the subscription
  # override the visit_overage features
  class ProblemWithPayment < Free
    def significance
      5
    end

    class Capabilities < Free::Capabilities
      def visit_overage
        parent_class.values_for(@site)[:visit_overage]
      end

      def visit_overage_unit
        parent_class.values_for(@site)[:visit_overage_unit]
      end

      def visit_overage_amount
        parent_class.values_for(@site)[:visit_overage_amount]
      end
    end
  end
end
