describe AddFreeDaysOrTrialSubscription do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:service) { AddFreeDaysOrTrialSubscription.new(site, 1.week) }

  before { stub_handle_overage(site, 100, 99) }

  context 'when site has no subscription (free)' do
    it 'calls AddTrialSubscription' do
      expect(AddTrialSubscription)
        .to receive_service_call
        .with(site, subscription: 'growth', trial_period: 1.week)

      service.call
    end
  end

  context 'when site has Growth subscription' do
    before { AddFreeDaysOrTrialSubscription.new(site, 1.week).call } # adds Growth trial

    it 'calls AddFreeDays' do
      expect(site).to be_capable_of :growth

      expect(AddFreeDays)
        .to receive_service_call
        .with(site, 1.week)

      service.call
    end
  end
end
