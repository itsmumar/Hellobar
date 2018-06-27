describe TrackAffiliateRefund do
  let(:bill) { create :bill }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:successful_response) { double 'Successful response', success?: true }
  let(:erroneous_response) { double 'Erroneous response', success?: false }
  let(:error) { 'Error' }

  describe '#call' do
    before do
      allow(TapfiliateGateway).to receive(:new).and_return gateway
    end

    context 'when there is no bill.tapfiliate_commission_id' do
      let!(:affiliate_commission) { nil }

      it 'does nothing' do
        expect(gateway).not_to receive :disapprove_commission

        TrackAffiliateRefund.new(bill).call
      end
    end

    context 'when there is bill.tapfiliate_commission_id' do
      let!(:affiliate_commission) { create :affiliate_commission, bill: bill, identifier: 999 }

      it 'sends `disapprove_commission` request to TapfiliateGateway' do
        expect(gateway)
          .to receive(:disapprove_commission)
          .with(commission_id: affiliate_commission.identifier)
          .and_return successful_response

        TrackAffiliateRefund.new(bill).call
      end
    end

    context 'when Tapfialite responds with an error' do
      let!(:affiliate_commission) { create :affiliate_commission, bill: bill, identifier: 999 }

      before do
        allow(erroneous_response).to receive(:[]).with('errors').and_return error

        expect(gateway)
          .to receive(:disapprove_commission)
          .with(commission_id: affiliate_commission.identifier)
          .and_return erroneous_response
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with a_string_matching(error)

        TrackAffiliateRefund.new(bill).call
      end
    end
  end
end
