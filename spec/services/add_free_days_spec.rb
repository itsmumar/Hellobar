describe AddFreeDays, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, :free_subscription, user: user }
  let(:days_number) { 10 }
  let(:service) { AddFreeDays.new(site, days_number) }
  let(:current_subscription) { site.current_subscription }
  let(:next_bill) { current_subscription.bills.last }
  let(:current_bill) { current_subscription.bills.first }

  %w[Pro Enterprise].each do |subscription|
    context "with #{ subscription } subscription" do
      before do
        stub_cyber_source :purchase
        ChangeSubscription.new(site, { subscription: subscription }, create(:credit_card)).call
      end

      it 'pushes next billing date forward' do
        expect { service.call }
          .to change { next_bill.reload.start_date }
          .by(10.days) \

          .and change { next_bill.reload.end_date }
          .by(10.days) \

          .and change { next_bill.reload.bill_at }
          .by(10.days) \

          .and change { current_bill.reload.end_date }
          .by(10.days)
      end
    end
  end

  context 'with trail subscription' do
    before do
      AddTrialSubscription.new(site, subscription: 'Pro', trial_period: '10').call
    end

    it 'adds free days to the trial' do
      expect { service.call }
        .to change { current_bill.reload.end_date }
        .by(10.days) \

        .and change { current_subscription.reload.trial_end_date }
        .by(10.days)
    end
  end

  context 'when days number is less than 1' do
    let(:days_number) { 0 }

    it 'raises error' do
      expect { service.call }
        .to raise_error(AddFreeDays::Error, 'Invalid number of days')
    end
  end

  %w[Free FreePlus ProComped ProManaged].each do |subscription|
    context "with #{ subscription } subscription" do
      before { ChangeSubscription.new(site, subscription: subscription).call }

      it 'raises error' do
        expect { service.call }
          .to raise_error(AddFreeDays::Error, 'Could not add trial days to a free subscription')
      end
    end
  end
end
