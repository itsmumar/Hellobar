describe TapfiliateGateway do
  let(:tapfiliate) { TapfiliateGateway.new }
  let(:user) { create :user, :affiliate }
  let(:headers) { Hash['Content-Type' => 'application/json'] }

  describe '#store_conversion' do
    it 'sends "store conversion with $0 commission" request to Tapfiliate' do
      stub_request(:post, /.*conversions\//).to_return status: 200

      tapfiliate.store_conversion user: user
    end
  end

  describe '#store_commission' do
    let(:user) { create :user, :affiliate, :with_pro_subscription_and_bill }
    let(:bill) { user.credit_cards.last.subscriptions.last.bills.last }

    it 'sends "store commission" request to Tapfiliate' do
      stub_request(:post, /.*conversions\/#{ user.affiliate_information.conversion_identifier }\/commissions\//)
        .to_return status: 200

      tapfiliate.store_commission bill: bill
    end
  end
end
