describe DeliverOnboardingCampaigns do
  let(:service) { DeliverOnboardingCampaigns.new }
  let(:create_bar_campaign) { double('create_bar_campaign') }
  let(:configure_bar_campaign) { double('configure_bar_campaign') }
  let(:user) { create :user }

  before do
    expect(CreateABarCampaign).to receive(:users).and_return([user])
    expect(ConfigureYourBarCampaign).to receive(:users).and_return([user])

    expect(CreateABarCampaign)
      .to receive(:new).with(user).and_return(create_bar_campaign)

    expect(ConfigureYourBarCampaign)
      .to receive(:new).with(user).and_return(configure_bar_campaign)
  end

  describe '#call' do
    it 'delivers CreateBarCampaign and ConfigureYourBarCampaign' do
      expect(DeliverUserOnboardingCampaign)
        .to receive_service_call
        .with(create_bar_campaign)

      expect(DeliverUserOnboardingCampaign)
        .to receive_service_call
        .with(configure_bar_campaign)

      service.call
    end
  end
end
