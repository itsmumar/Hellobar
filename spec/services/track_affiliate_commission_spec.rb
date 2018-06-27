describe TrackAffiliateCommission do
  let(:user) { create :user, :affiliate, :with_pro_subscription_and_bill }
  let(:bill) { user.credit_cards.last.subscriptions.last.bills.last }
  let(:amount) { bill.amount }
  let(:comment) { "Paid Bill##{ bill.id }" }
  let(:conversion_identifier) { user.affiliate_information.conversion_identifier }
  let(:gateway) { instance_double TapfiliateGateway }
  let(:track_commission) { TrackAffiliateCommission.new(bill) }
  let(:successful_response) { double 'Successful response', success?: true }
  let(:erroneous_response) { double 'Erroneous response', success?: false }
  let(:error) { 'Error' }

  describe '#call' do
    before do
      allow(TapfiliateGateway).to receive(:new).and_return gateway
    end

    it 'does nothing when there is no affiliate information' do
      bill = create :bill, :paid

      expect(gateway).not_to receive :store_commission

      TrackAffiliateCommission.new(bill).call
    end

    context 'when TapfiliateGateway responds with success' do
      before do
        allow(gateway)
          .to receive(:store_commission)
          .with(conversion_identifier: conversion_identifier, amount: amount, comment: a_string_matching(comment))
          .and_return successful_response

        allow(successful_response)
          .to receive(:[])
          .with(0)
          .and_return({ 'id' => 999 })
      end

      it 'sends `store_commission` request to TapfiliateGateway' do
        track_commission.call
        expect(gateway).to have_received(:store_commission)
      end

      it 'creates AffiliateCommission' do
        expect { track_commission.call }
          .to change { AffiliateCommission.count }
          .from(0)
          .to(1)

        expect(AffiliateCommission.last.identifier).to eql 999
        expect(AffiliateCommission.last.bill).to eql bill
      end
    end

    context 'when Tapfialite responds with an error' do
      before do
        allow(erroneous_response).to receive(:[]).with('errors').and_return error

        expect(gateway).to receive(:store_commission)
          .with(conversion_identifier: conversion_identifier, amount: amount, comment: a_string_matching(comment))
          .and_return erroneous_response
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with a_string_matching(error)

        track_commission.call
      end
    end
  end
end
