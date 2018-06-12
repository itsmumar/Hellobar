describe TapfiliateGateway do
  let(:tapfiliate) { TapfiliateGateway.new }
  let(:user) { create :user, :affiliate }

  describe '#store_conversion' do
    let(:conversion_id) { '6' }
    let(:headers) { Hash['Content-Type' => 'application/json'] }
    let(:body) { Hash[id: conversion_id] }

    it 'sends $0 commission request to Tapfiliate' do
      stub_request(:post, /.*conversions\//).to_return status: 200

      tapfiliate.store_conversion user: user
    end

    it 'stores Tapfilate conversion id in affiliate information' do
      stub_request(:post, /.*conversions\//)
        .to_return status: 200, body: body.to_json, headers: headers

      tapfiliate.store_conversion user: user

      expect(user.affiliate_information.conversion_identifier).to eq conversion_id
    end
  end
end
