describe RegistrationForm do
  let(:params) { Hash[site_url: 'http://site.com', email: 'me@example.com', password: '1'] }
  let(:form) { RegistrationForm.new(params, cookies) }
  let(:affiliate_identifier) { 'aid' }

  describe '#title / #cta' do
    context 'regular signup' do
      let(:cookies) { {} }

      it 'displays default title' do
        expect(form.title).to eql 'Create Your Free Account'
      end

      it 'displays default cta' do
        expect(form.cta).to eql 'Create Your Free Account'
      end
    end

    context 'signup for paid plan from the website' do
      let(:cookies) { Hash[the_plan: 'paid'] }

      it 'displays paid title' do
        expect(form.title).to include 'Create Your Account'
      end

      it 'displays paid cta' do
        expect(form.cta).to include 'Create Your Account Now'
      end
    end

    context 'promotional signup' do
      let(:cookies) { Hash[promotional_signup: 'true'] }

      it 'displays promotional signup title' do
        expect(form.title).to include 'FREE 30 Day Trial Of Hello Bar Growth'
      end

      it 'displays promotional signup cta' do
        expect(form.cta).to include 'Start Your 30 Day Free Trial'
      end
    end

    context 'affiliate signup without partner record' do
      let(:cookies) { Hash[tap_vid: 'vid', tap_aid: affiliate_identifier] }

      it 'displays affiliate signup title' do
        expect(form.title).to include 'FREE 30 Day Trial Of Hello Bar Growth'
      end

      it 'displays affiliate signup cta' do
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

    context 'neil signup' do
      let(:cookies) { Hash[neil_signup: 'true'] }

      it 'displays neil signup title' do
        expect(form.title)
          .to include 'Hey Neil Patel Fans! Grab Your Cyber Monday 50% Off Deal (24 Hours Only)'
      end

      it 'displays neil signup cta' do
        expect(form.cta).to include 'Sign Up & Save Now'
      end
    end

    context 'ask method signup' do
      let(:cookies) { Hash[dollar_trial: 'true'] }

      it 'displays ask method signup title' do
        expect(form.title)
          .to include 'Hey ASK Method Fans! Get Your 30 Day Trial of Hello Bar for Just $1 (48 Hours Only)'
      end

      it 'displays neil signup cta' do
        expect(form.cta).to include 'Sign Up For $1 Now'
      end
    end
  end
end
