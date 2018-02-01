describe UpdateCampaign do
  subject(:service) { UpdateCampaign.new(campaign, attributes) }

  let(:attributes) { { name: 'New Campaign' } }

  describe '#call' do
    context 'when campaign can be edited' do
      let(:campaign) { create(:campaign) }

      it 'updates the campaign' do
        expect(campaign).to receive(:update!)

        service.call
      end

      context 'with invalid attributes' do
        let(:attributes) { { name: '' } }

        it 'raises error' do
          expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when campaign can not be edited' do
      let(:campaign) { create(:campaign, status: Campaign::SENT) }

      it 'raises error' do
        expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
