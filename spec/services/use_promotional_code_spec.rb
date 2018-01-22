describe UsePromotionalCode do
  describe '#call' do
    let(:site) { double 'Site' }

    context 'when no promotional code provided' do
      it 'does not add trial days' do
        expect(AddTrialSubscription).not_to receive_service_call

        UsePromotionalCode.new(site, nil).call
      end
    end

    context 'when promotional code is incorrect' do
      it 'does not add trial days' do
        create :coupon, :promotional

        expect(AddTrialSubscription).not_to receive_service_call

        UsePromotionalCode.new(site, '123').call
      end
    end

    context 'when promotional code is correct' do
      it 'adds trial days to current subscription' do
        coupon = create :coupon, :promotional

        expect(AddTrialSubscription)
          .to receive_service_call
          .with site, hash_including(subscription: 'pro')

        UsePromotionalCode.new(site, coupon.label).call
      end
    end
  end
end
