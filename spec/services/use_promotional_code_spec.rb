describe UsePromotionalCode do
  let(:user) { create :user }

  describe '#call' do
    let(:site) { double 'Site' }

    context 'when no promotional code provided' do
      it 'does not add trial days' do
        expect(AddTrialSubscription).not_to receive_service_call

        UsePromotionalCode.new(site, user, nil).call
      end
    end

    context 'when promotional code is incorrect' do
      it 'does not add trial days' do
        create :coupon, :promotional

        expect(AddTrialSubscription).not_to receive_service_call

        UsePromotionalCode.new(site, user, '123').call
      end
    end

    context 'when promotional code is correct' do
      let(:user) { create :user }
      let(:site) { create :site, user: user }
      let(:coupon) { create :coupon, :promotional }
      let(:bill) { create :bill, site: site }

      it 'adds trial days to current subscription' do
        expect(AddTrialSubscription)
          .to receive_service_call
          .with(site, hash_including(subscription: 'pro'))
          .and_return(bill)

        UsePromotionalCode.new(site, user, coupon.label).call
      end

      it 'creates CouponUse' do
        expect { UsePromotionalCode.new(site, user, coupon.label).call }
          .to change { site.coupon_uses.count }
          .by(1)
      end

      it 'tracks "used-promo-code" event' do
        expect(TrackEvent)
          .to receive_service_call
          .with(:used_promo_code, user: user, code: coupon.label)

        UsePromotionalCode.new(site, user, coupon.label).call
      end
    end
  end
end
