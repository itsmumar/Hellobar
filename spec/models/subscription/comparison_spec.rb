describe Subscription::Comparison do
  let(:subscriptions) do
    [
      Subscription::Free,
      Subscription::FreePlus,
      Subscription::Pro,
      Subscription::Elite,
      Subscription::ProComped,
      Subscription::ProManaged,
      Subscription::ProSpecial
    ]
  end

  def compare from_subscription, to_subscription
    Subscription::Comparison.new(from_subscription.new, to_subscription.new)
  end

  describe '#upgrade?' do
    # for `Free` selects FreePlus, Pro, Elite, ProComped and ProManaged
    # for `FreePlus` selects Pro, Elite, ProComped and ProManaged
    # for `Pro` selects Elite, ProComped and ProManaged
    # etc.
    def subscription_to_upgrade from_subscription
      subscriptions.select do |subscription|
        subscriptions.index(subscription) >
          subscriptions.index(from_subscription)
      end
    end

    def each_upgrade_available
      subscriptions.each do |from_subscription|
        subscription_to_upgrade(from_subscription).each do |to_subscription|
          yield compare(from_subscription, to_subscription)
        end
      end
    end

    specify do
      each_upgrade_available do |comparison|
        expect(comparison).not_to be_downgrade
        expect(comparison).not_to be_same_plan
        expect(comparison).to be_upgrade
      end
    end
  end

  describe '#downgrade?' do
    # for `ProManaged` selects Free, FreePlus, Pro, Elite, ProComped
    # for `ProComped` selects Free, FreePlus, Pro, Elite
    # etc.
    def subscription_to_downgrade from_subscription
      subscriptions.select do |subscription|
        subscriptions.index(subscription) <
          subscriptions.index(from_subscription)
      end
    end

    def each_downgrade_available
      subscriptions.each do |from_subscription|
        subscription_to_downgrade(from_subscription).each do |to_subscription|
          yield compare(from_subscription, to_subscription)
        end
      end
    end

    specify do
      each_downgrade_available do |comparison|
        expect(comparison).not_to be_upgrade
        expect(comparison).not_to be_same_plan
        expect(comparison).to be_downgrade
      end
    end
  end

  describe '#same_plan?' do
    def each_subscription
      subscriptions.each do |subscription|
        yield compare(subscription, subscription)
      end
    end

    specify do
      each_subscription do |comparison|
        expect(comparison).not_to be_upgrade
        expect(comparison).not_to be_downgrade
        expect(comparison).to be_same_plan
      end
    end
  end
end
