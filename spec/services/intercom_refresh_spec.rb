describe IntercomRefresh do
  subject!(:service) { IntercomRefresh.new }

  before do
    allow(IntercomRefresh).to receive(:new)
    allow(TrackEvent).to receive_service_call

    stub_cyber_source :purchase
  end

  context 'when bill subscription is pro' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :pro, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for pro' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Pro'
        )
      service.call
    end
  end

  context 'when bill subscription is growth' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :growth, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for growth' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Growth'
        )
      service.call
    end
  end

  context 'when bill subscription is elite' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :elite, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for elite' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Elite'
        )
      service.call
    end
  end

  context 'when bill subscription is pro_comped' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :pro_comped, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for pro_comped' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Pro Comped'
        )
      service.call
    end
  end

  context 'when bill subscription is pro_managed' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :pro_managed, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for pro_managed' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Pro Managed'
        )
      service.call
    end
  end

  context 'when bill subscription is pro_special' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :pro_special, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for pro_special' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Pro'
        )
      service.call
    end
  end

  context 'when bill subscription is custom 1' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :custom_1, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for custom 1' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Custom 1'
        )
      service.call
    end
  end

  context 'when bill subscription is custom 2' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :custom_2, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for custom 1' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Custom 2'
        )
      service.call
    end
  end

  context 'when bill subscription is custom 3' do
    let!(:user) { create :user }
    let(:credit_card) { create :credit_card }
    let!(:site) { create :site, :custom_3, :with_rule, user: user, script_installed_at: Date.yesterday }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site }

    it 'tracks for custom 3' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :added_dme,
          user: site.owners.first,
          highest_subscription_name: 'Custom 3'
        )
      service.call
    end
  end
end
