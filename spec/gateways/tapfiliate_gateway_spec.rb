describe TapfiliateGateway do
  let(:tapfiliate) { TapfiliateGateway.new }
  let(:user) { create :user, :affiliate }
  let(:headers) { Hash['Content-Type' => 'application/json'] }

  describe '#disapprove_commission' do
    let(:commission_id) { 999 }

    it 'sends "disapprove commission" request to Tapfiliate' do
      stub_request(:delete, /commissions\/#{ commission_id }\/approved/)
        .to_return status: 200

      tapfiliate.disapprove_commission commission_id: commission_id
    end
  end

  describe '#store_conversion' do
    it 'sends "store conversion with $0 commission" request to Tapfiliate' do
      stub_request(:post, /.*conversions\//).to_return status: 200

      tapfiliate.store_conversion user: user
    end
  end

  describe '#store_commission' do
    let(:user) { create :user, :affiliate, :with_pro_subscription_and_bill }
    let(:bill) { user.credit_cards.last.subscriptions.last.bills.last }
    let(:amount) { bill.amount }
    let(:comment) { "Paid Bill##{ bill.id }" }
    let(:conversion_identifier) { user.affiliate_information.conversion_identifier }

    it 'sends "store commission" request to Tapfiliate' do
      stub_request(:post, /.*conversions\/#{ conversion_identifier }\/commissions\//)
        .to_return status: 200

      tapfiliate.store_commission conversion_identifier: conversion_identifier, amount: amount, comment: comment
    end
  end
end
