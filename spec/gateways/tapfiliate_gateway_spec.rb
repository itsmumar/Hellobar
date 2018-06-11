describe TapfiliateGateway do
  let(:tapfiliate) { TapfiliateGateway.new }
  let(:user) { create :user, :affiliate }

  describe '#track_signup' do
    it 'sends $0 commission request to Tapfiliate' do
      stub_request(:post, /.*conversions\//).to_return status: 200

      tapfiliate.track_signup user: user
    end
  end
end
