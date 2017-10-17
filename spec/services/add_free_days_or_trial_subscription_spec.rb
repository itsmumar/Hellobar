describe AddFreeDaysOrTrialSubscription do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:service) { AddFreeDaysOrTrialSubscription.new(site, 1.week) }

  context 'when site has no subscription (free)' do
    it 'calls AddTrialSubscription' do
      expect(AddTrialSubscription)
        .to receive_service_call
        .with(site, subscription: 'pro', trial_period: 1.week)

      service.call
    end
  end

  context 'when site has Pro subscription' do
    before { AddFreeDaysOrTrialSubscription.new(site, 1.week).call } # adds Pro trial

    it 'calls AddFreeDays' do
      expect(site).to be_capable_of :pro

      expect(AddFreeDays)
        .to receive_service_call
        .with(site, 1.week)

      service.call
    end
  end
end
