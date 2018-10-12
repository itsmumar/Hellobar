describe AddFreeDays, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, :free_subscription, user: user }
  let(:days_number) { 10 }
  let(:duration) { days_number.days }
  let(:service) { AddFreeDays.new(site, days_number) }
  let(:current_subscription) { site.current_subscription }
  let(:next_bill) { current_subscription.bills.last }
  let(:current_bill) { current_subscription.bills.first }

  %w[Pro Elite].each do |subscription|
    context "with #{ subscription } subscription" do
      before do
        stub_cyber_source :purchase
        stub_handle_overage(site, 100, 99)
        ChangeSubscription.new(site, { subscription: subscription }, create(:credit_card)).call
      end

      it 'pushes next billing date forward' do
        expect { service.call }
          .to change { next_bill.reload.start_date }
          .by(duration) \
          .and change { next_bill.reload.end_date }
          .by(duration) \
          .and change { next_bill.reload.bill_at }
          .by(duration) \
          .and change { current_bill.reload.end_date }
          .by(duration)
      end
    end
  end

  context 'with trial subscription' do
    before do
      AddTrialSubscription.new(site, subscription: 'Pro', trial_period: days_number).call
    end

    it 'pushes next billing date forward' do
      expect { service.call }
        .to change { next_bill.reload.start_date }
        .by(duration) \
        .and change { next_bill.reload.end_date }
        .by(duration) \
        .and change { next_bill.reload.bill_at }
        .by(duration) \
        .and change { current_bill.reload.end_date }
        .by(duration)
    end

    it 'adds free days to the trial' do
      expect { service.call }
        .to change { current_subscription.reload.trial_end_date }
        .by(duration)
    end

    context 'when next bill does not exist' do
      before do
        next_bill.destroy
      end

      it 'creates the bill for next period' do
        service.call

        new_bill = current_subscription.bills.last
        expect(new_bill).not_to eq(current_bill)
        expect(new_bill).to be_pending
        expect(new_bill.amount).to be > 0
        expect(new_bill.start_date).not_to eq(duration.from_now)
      end
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
      before do
        stub_handle_overage(site, 100, 99)
        ChangeSubscription.new(site, subscription: subscription).call
       end

      it 'raises error' do
        expect { service.call }
          .to raise_error(AddFreeDays::Error, 'Could not add trial days to a free subscription')
      end
    end
  end
end
