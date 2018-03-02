describe CreateCampaign do
  subject(:service) { described_class.new(site, attributes) }

  let(:site) { create(:site) }
  let(:contact_list) { create :contact_list }
  let(:campaign_attributes) { attributes_for(:campaign, contact_list_id: contact_list.id) }
  let(:email_attributes) { attributes_for(:email) }
  let(:attributes) { campaign_attributes.merge(email_attributes) }

  describe '#call' do
    it 'creates a new campaign' do
      expect { service.call }.to change { Campaign.count }.by(1)
    end

    it 'creates a new email' do
      expect { service.call }.to change { Email.count }.by(1)
    end

    it 'returns created campaign' do
      campaign = service.call

      expect(campaign).to be_a(Campaign)
      expect(campaign).to be_persisted
      expect(campaign.attributes.symbolize_keys).to include(campaign_attributes)
    end

    it 'returns created email' do
      campaign = service.call

      expect(campaign.email).to be_an(Email)
      expect(campaign.email).to be_persisted
      expect(campaign.email.attributes.symbolize_keys).to include(email_attributes)
    end

    context 'when campaign attributes are not valid' do
      let(:campaign_attributes) { { name: '' } }

      it 'raises error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not create a new campaign' do
        expect { service.call rescue nil }.not_to change { Campaign.count } # rubocop:disable Style/RescueModifier
      end

      it 'does not create a new email' do
        expect { service.call rescue nil }.not_to change { Email.count } # rubocop:disable Style/RescueModifier
      end
    end

    context 'when email attributes are not valid' do
      let(:email_attributes) { { from_name: '' } }

      it 'raises error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'does not create a new campaign' do
        expect { service.call rescue nil }.not_to change { Campaign.count } # rubocop:disable Style/RescueModifier
      end

      it 'does not create a new email' do
        expect { service.call rescue nil }.not_to change { Email.count } # rubocop:disable Style/RescueModifier
      end
    end
  end
end
