describe HandleOverageSite do
  let(:site) { create :site, :with_user, subscription_type }
  let(:number_of_views) { 999 }
  let(:limit) { 100 }
  let(:service) { HandleOverageSite.new(site, number_of_views, limit) }

  before { allow(TrackEvent).to receive_service_call }

  shared_examples 'tracks events' do
    it 'tracks "exceeded_views_limit" event' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :exceeded_views_limit,
          user: site.owners.first,
          site: site,
          number_of_views: number_of_views,
          limit: limit
        )
      service.call
    end
  end

  context 'with Elite subscription' do
    let(:subscription_type) { :elite }
    include_examples 'tracks events'
  end

  context 'with Elite & into overage counts' do
    let(:subscription_type) { :elite }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Elite Special subscription' do
    let(:subscription_type) { :elite_special }
    include_examples 'tracks events'
  end

  context 'with Elite Special & into overage counts' do
    let(:subscription_type) { :elite_special }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Custom 1 subscription' do
    let(:subscription_type) { :custom_1 }
    include_examples 'tracks events'
  end

  context 'with Custom 1 & into overage counts' do
    let(:subscription_type) { :custom_1 }
    let(:number_of_views) { 5_000_001 }
    let(:limit) { 5_000_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Custom 1 & into second overage increment' do
    let(:subscription_type) { :custom_1 }
    let(:number_of_views) { 5_250_001 }
    let(:limit) { 5_000_000 }
    it 'increments the overage count by 2' do
      service.call
      expect(site.overage_count).to eql(3)
    end
  end

  context 'with Custom 2 subscription' do
    let(:subscription_type) { :custom_2 }
    include_examples 'tracks events'
  end

  context 'with Custom 2 & into overage counts' do
    let(:subscription_type) { :custom_2 }
    let(:number_of_views) { 10_000_001 }
    let(:limit) { 10_000_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Custom 2 & into second overage increment' do
    let(:subscription_type) { :custom_2 }
    let(:number_of_views) { 10_250_001 }
    let(:limit) { 10_000_000 }
    it 'increments the overage count by 2' do
      service.call
      expect(site.overage_count).to eql(3)
    end
  end

  context 'with Custom 3 subscription' do
    let(:subscription_type) { :custom_3 }
    include_examples 'tracks events'
  end

  context 'with Custom 3 & into overage counts' do
    let(:subscription_type) { :custom_3 }
    let(:number_of_views) { 20_000_001 }
    let(:limit) { 20_000_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Custom 3 & into second overage increment' do
    let(:subscription_type) { :custom_3 }
    let(:number_of_views) { 20_250_001 }
    let(:limit) { 20_000_000 }
    it 'increments the overage count by 3' do
      service.call
      expect(site.overage_count).to eql(3)
    end
  end

  context 'with ProManaged subscription' do
    let(:subscription_type) { :pro_managed }
    include_examples 'tracks events'
  end

  context 'with ProComped subscription' do
    let(:subscription_type) { :pro_comped }
    include_examples 'tracks events'
  end

  context 'with Growth subscription' do
    let(:subscription_type) { :growth }
    include_examples 'tracks events'
  end

  context 'with Growth & into overage counts' do
    let(:subscription_type) { :growth }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Growth & into overage counts on free trials' do
    let(:subscription_type) { :growth }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    let(:add_trial) { AddTrialSubscription.new(site, subscription: 'Growth', trial_period: 30) }

    it 'does not increment the overage count by 1' do
      add_trial.call
      service.call
      expect(site.overage_count).not_to eql(1)
    end
  end

  context 'with Pro subscription' do
    let(:subscription_type) { :pro }
    include_examples 'tracks events'
  end

  context 'with Pro & into overage counts' do
    let(:subscription_type) { :pro }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with Pro Special subscription' do
    let(:subscription_type) { :pro_special }
    include_examples 'tracks events'
  end

  context 'with Pro Special & into overage counts' do
    let(:subscription_type) { :pro_special }
    let(:number_of_views) { 25_001 }
    let(:limit) { 25_000 }
    it 'increments the overage count by 1' do
      service.call
      expect(site.overage_count).to eql(1)
    end
  end

  context 'with FreePlus subscription' do
    let(:subscription_type) { :free_plus }
    include_examples 'tracks events'
  end

  context 'with Free subscription' do
    let(:subscription_type) { :free }

    it 'tracks "free_overage" event' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :free_overage,
          user: site.owners.first,
          site: site
        )

      service.call
    end

    include_examples 'tracks events'

    it 'decrements the active site elements count to 0' do
      site.deactivate_site_element
      expect(site.site_elements.active.count).to eql(0)
    end
  end
end
