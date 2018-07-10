describe RegistrationForm do
  let(:params) { Hash[site_url: 'http://site.com', email: 'me@example.com', password: '1'] }
  let(:form) { RegistrationForm.new(params, cookies) }
  let(:affiliate_identifier) { 'aid' }

  describe '#title / #cta' do
    context 'regular signup' do
      let(:cookies) { {} }

      it 'displays default title' do
        expect(form.title).to eql 'Create free account'
      end

      it 'displays default cta' do
        expect(form.cta).to eql 'Create free account'
      end
    end

    context 'affiliate trial signup without partner record' do
      let(:cookies) { Hash[tap_vid: 'vid', tap_aid: affiliate_identifier] }

      it 'displays trial signup title' do
        expect(form.title).to include 'FREE 30 Day Trial Of Hello Bar Growth'
      end

      it 'displays trial signup cta' do
        expect(form.cta).to include 'Start Your 30 Day Free Trial'
      end
    end

    context 'affiliate signup with partner record' do
      let(:cookies) { Hash[tap_vid: 'vid', tap_aid: affiliate_identifier] }
      let(:community) { 'My Community' }

      before do
        create :partner, partner_plan_id: PartnerPlan.find('growth_90').id,
          affiliate_identifier: affiliate_identifier, community: community
      end

      it 'displays partner signup title' do
        expect(form.title).to include 'FREE 90 Day Trial Of Hello Bar Growth'
        expect(form.title).to include community
      end

      it 'displays partner signup cta' do
        expect(form.cta).to include 'Start Your 90 Day Free Trial'
      end
    end
  end
end
