require 'spec_helper'

describe UserOnboardingCampaign do
  describe 'UserOnboardingCampaign.deliver_all_onboarding_campaign_email!' do
    before do
      klass = UserOnboardingCampaign.onboarding_campaign_classes.first
      klass.stub(:users).and_return([double('User', current_onboarding_status: nil)])
      klass.stub(:new).and_return(mock_campaign)
    end
    let(:mock_campaign) {double('UserOnboardingCampaign')}

    it 'will not deliver email without a being in the campaign sequence' do
      allow(mock_campaign).to receive(:current_campaign_sequence) {nil}

      expect(mock_campaign).to_not receive(:deliver_campaign_email!)

      UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
    end

    describe 'when the campaign is in the campaign sequence' do
      before {allow(mock_campaign).to receive(:current_campaign_sequence) {1}}

      it 'will attempt to deliver email' do
        expect(mock_campaign).to receive(:deliver_campaign_email!)

        UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
      end

      it 'will not mark a sequence delivered without delivering the email' do
        allow(mock_campaign).to receive(:deliver_campaign_email!) {false}
        expect(mock_campaign).to_not receive(:mark_sequence_delivered!)

        UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
      end

      it 'will mark the sequence delivered after delivering the email' do
        allow(mock_campaign).to receive(:deliver_campaign_email!) {true}
        expect(mock_campaign).to receive(:mark_sequence_delivered!)

        UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
      end
    end
  end
end
