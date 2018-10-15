class Subscription
  class Comparison
    def initialize(from_subscription, to_subscription)
      @from_subscription_index = index_of(from_subscription)
      @to_subscription_index = index_of(to_subscription)
    end

    def upgrade?
      @from_subscription_index < @to_subscription_index
    end

    def downgrade?
      @from_subscription_index > @to_subscription_index
    end

    def same_plan?
      @from_subscription_index == @to_subscription_index
    end

    private

    # These need to be in the order of least expensive to most expensive
    # order means:
    # ----> upgrading
    # <---- downgrading
    def plans
      [Free, FreePlus, Pro, Growth, ProSpecial, ProComped, ProManaged, EliteSpecial, Elite, Custom1, Custom2, Custom3].map(&:name)
    end

    def index_of(subscription)
      plans.index(subscription.class.name) ||
        raise("Could not find subscription class #{ subscription.class.name.inspect }")
    end
  end
end
