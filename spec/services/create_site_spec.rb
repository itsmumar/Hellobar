describe CreateSite do
  let(:site) { build :site }
  let(:referral_token) { '' }
  let(:user) { create :user }
  let(:session) { Hash[referral_token: referral_token] }
  let(:service) { CreateSite.new(site, user, **session) }

  it 'persists site' do
    expect { service.call }.to change(Site, :count).by(1)
  end

  it 'creates SiteMembership' do
    expect { service.call }.to change(SiteMembership, :count).by(1)
  end

  it 'creates default rules' do
    expect { service.call }.to change(Rule, :count).by(3)
  end

  it 'calls Referrals::HandleToken' do
    expect(Referrals::HandleToken)
      .to receive(:run)
      .with(user: user, token: referral_token)

    service.call
  end

  it 'calls DetectInstallType' do
    expect(DetectInstallType).to receive_service_call.with(site)

    service.call
  end

  it 'calls ChangeSubscription with :free subscription' do
    expect(ChangeSubscription)
      .to receive_service_call
      .with(site, subscription: 'free', schedule: 'monthly')

    service.call
  end

  it 'calls TrackEvent with :created_site event' do
    expect(TrackEvent)
      .to receive_service_call
      .with(:created_site, site: site, user: user)

    service.call
  end

  it 'regenerates script' do
    expect { service.call }
      .to have_enqueued_job(GenerateStaticScriptJob).with(site)
  end

  context 'when URL is already in use by user' do
    let!(:existing_site) { create :site, user: user, url: site.url }

    it 'raises DuplicateURLError' do
      expect { service.call }.to raise_error CreateSite::DuplicateURLError do |error|
        expect(error.existing_site).to eql existing_site
        expect(error.message).to eql 'Url is already in use.'
      end
    end
  end

  context 'when URL is invalid' do
    let(:site) { build(:site, url: 'qqq') }

    it 'raises an error' do
      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when user signs up from the promotional page' do
    let(:cookies) { Hash[promotional_signup: 'true'] }
    let(:service) { CreateSite.new(site, user, cookies: cookies, referral_token: '') }

    it 'creates trial subscription' do
      expect(ChangeSubscription).not_to receive_service_call
      expect(AddTrialSubscription).to receive_service_call.with(instance_of(Site), subscription: 'growth', trial_period: 30)

      service.call
    end
  end

  context 'when user signs up from an affiliate link' do
    let(:affiliate_identifier) { 'qwe123' }

    context 'when there is an associated partner record' do
      let(:partner_plan) { PartnerPlan.find('growth_60') }

      before do
        create(:partner, affiliate_identifier: affiliate_identifier, partner_plan: partner_plan)
        create(:affiliate_information, user: user, affiliate_identifier: affiliate_identifier)
      end

      it 'creates trial subscription' do
        expect(ChangeSubscription).not_to receive_service_call
        expect(AddTrialSubscription).to receive_service_call.with(instance_of(Site), subscription: 'growth', trial_period: 60)

        service.call
      end
    end

    context 'when there is no partner record' do
      let(:partner_plan) { Partner.default_partner_plan }

      before do
        create(:affiliate_information, user: user, affiliate_identifier: affiliate_identifier)
      end

      it 'creates default trial subscription' do
        expect(ChangeSubscription).not_to receive_service_call
        expect(AddTrialSubscription).to receive_service_call.with(instance_of(Site), subscription: partner_plan.subscription_type, trial_period: partner_plan.duration)

        service.call
      end
    end
  end
end
