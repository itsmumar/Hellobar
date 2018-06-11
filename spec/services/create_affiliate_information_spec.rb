describe CreateAffiliateInformation do
  describe '#call' do
    let(:user) { create :user }
    let(:aid) { 'aid' }
    let(:vid) { 'vid' }
    let(:cookies) { Hash[tap_aid: aid, tap_vid: vid] }

    it 'does nothing when affiliate cookies are not set' do
      expect {
        CreateAffiliateInformation.new(user, {}).call
      }.not_to change { AffiliateInformation.count }
    end

    it 'stores affiliate information from cookies' do
      info = CreateAffiliateInformation.new(user, cookies).call

      expect(info).to be_persisted
      expect(info).to be_an AffiliateInformation
      expect(info.affiliate_identifier).to eql aid
      expect(info.visitor_identifier).to eql vid
    end
  end
end
