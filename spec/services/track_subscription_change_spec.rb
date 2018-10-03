describe TrackSubscriptionChange do
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }

  let(:free_subscription) { create(:subscription, :free, site: site) }
  let(:pro_subscription) { create(:subscription, :pro, site: site) }
  let(:pro_subscription_yearly) { create(:subscription, :pro, :yearly, site: site) }
  let(:elite_subscription) { create(:subscription, :elite, site: site) }

  before do
    allow(TrackEvent).to receive_message_chain(:new, :call)
  end

  shared_examples 'tracks event' do |event_name|
    it "tracks #{ event_name } event" do
      expect(TrackEvent).to receive_service_call.with(
        event_name,
        user: user,
        subscription: new_subscription,
        previous_subscription: old_subscription
      )

      expect(HandleUnfreezeFrozenAccount).to receive_service_call if old_subscription.name == 'Free'
      expect(ResetEmailSentFields).to receive_service_call if old_subscription == 'Free'

      described_class.new(user, old_subscription, new_subscription).call
    end
  end

  shared_examples 'no events' do
    it 'does not track any event' do
      expect(TrackEvent).not_to receive_service_call

      described_class.new(user, old_subscription, new_subscription).call
    end
  end

  context 'when first subscription is "free"' do
    include_examples 'no events' do
      let(:old_subscription) { nil }
      let(:new_subscription) { free_subscription }
    end
  end

  context 'when subscription is upgraded from "free" to "pro"' do
    include_examples 'tracks event', :upgraded_subscription do
      let(:old_subscription) { free_subscription }
      let(:new_subscription) { pro_subscription }
    end
  end

  context 'when subscription is upgraded from "pro" to "elite"' do
    include_examples 'tracks event', :upgraded_subscription do
      let(:old_subscription) { pro_subscription }
      let(:new_subscription) { elite_subscription }
    end
  end

  context 'when subscription is downgraded from "pro" to "free"' do
    include_examples 'tracks event', :downgraded_subscription do
      let(:old_subscription) { pro_subscription }
      let(:new_subscription) { free_subscription }
    end
  end

  context 'when subscription is downgraded from "elite" to "pro"' do
    include_examples 'tracks event', :downgraded_subscription do
      let(:old_subscription) { elite_subscription }
      let(:new_subscription) { pro_subscription }
    end
  end

  context 'when schedule period is changed within the same subscription' do
    include_examples 'no events' do
      let(:old_subscription) { pro_subscription }
      let(:new_subscription) { pro_subscription_yearly }
    end
  end
end
