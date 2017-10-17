describe RedeemReferralForSender do
  let!(:coupon) { create :coupon, :referral }

  let(:sender) { create :user }
  let(:site) { create :site, user: sender }

  let(:service) { RedeemReferralForSender.new(referral) }

  context 'when referral available to sender' do
    let!(:referral) do
      create(:referral, state: :installed, available_to_sender: true, sender: sender, site: site)
    end

    context 'and site is on Free subscription', :freeze do
      it 'adds trial Pro subscription' do
        expect { service.call }
          .to change { site.reload.active_subscription }
          .to instance_of(Subscription::Pro)

        expect(site.active_subscription.trial_end_date).to eql 1.month.from_now
      end
    end

    context 'and site is on a paid subscription' do
      let(:credit_card) { create :credit_card }

      before { stub_cyber_source :purchase }
      before { ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call }

      it 'adds free days', :freeze do
        expect { service.call }
          .not_to change { site.reload.active_subscription }

        # 1 month is paid and 1 month is given by referral
        expect(site.active_subscription.active_until).to eql 2.months.from_now
      end
    end
  end

  context 'when referral is not available to sender' do
    let!(:referral) do
      create(:referral, state: :installed, available_to_sender: false)
    end

    it 'raises RedeemReferralForSender::ReferralNotAvailable' do
      expect { service.call }
        .to raise_error(RedeemReferralForSender::ReferralNotAvailable)
    end
  end

  context 'when site has a failed bill' do
    let!(:referral) do
      create(:referral, state: :installed, available_to_sender: true, sender: sender, site: site)
    end
    let(:credit_card) { create :credit_card }

    before { stub_cyber_source :purchase }
    before { ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call }
    before { site.bills.last.failed! }

    let!(:failed_bill) { Bill.failed.last }

    it 'marks failed bill as paid' do
      expect { service.call }
        .to change(site.bills.failed, :count)
        .by(-1)
        .and change(site.bills.paid, :count)
        .by(1)

      expect(failed_bill.reload).to be_paid
    end

    it 'creates pending bill for next period' do
      expect { service.call }
        .to change(site.bills.pending, :count)
        .by(1)
    end
  end
end
