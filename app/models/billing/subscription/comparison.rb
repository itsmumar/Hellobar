class Subscription
  class Comparison
    attr_reader :from_subscription, :to_subscription, :direction

    def initialize(from_subscription, to_subscription)
      @from_subscription = from_subscription
      @to_subscription = to_subscription
      from_index = to_index = nil

      plans.each_with_index do |plan, index|
        from_index = index if from_subscription.is_a?(plan)
        to_index = index if to_subscription.is_a?(plan)
      end

      raise "Could not find plans (from_subscription: #{ from_subscription.inspect } and to_subscription: #{ to_subscription.inspect }, got #{ from_index.inspect } and #{ to_index.inspect }" unless from_index && to_index

      @direction =
        if from_index == to_index
          0
        elsif from_index > to_index
          -1
        else
          1
        end
    end

    def upgrade?
      @direction > 0
    end

    def downgrade?
      !upgrade?
    end

    def same_plan?
      @direction == 0
    end

    private

    # These need to be in the order of least expensive to most expensive
    def plans
      [Free, Pro, Enterprise]
    end
  end
end
