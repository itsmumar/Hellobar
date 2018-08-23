describe HandleOverageSite do
  let(:site) { create :site, subscription_type }
  let(:number_of_views) { 999 }
  let(:limit) { 100 }
  let(:service) { HandleOverageSite.new(site, number_of_views, limit) }

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

  context 'with Enterprise subscription' do
    let(:subscription_type) { :enterprise }
    include_examples 'tracks events'
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

  context 'with Pro subscription' do
    let(:subscription_type) { :pro }
    include_examples 'tracks events'
  end

  context 'with FreePlus subscription' do
    let(:subscription_type) { :free_plus }
    include_examples 'tracks events'
  end

  context 'with Free subscription' do
    let(:subscription_type) { :free }
    include_examples 'tracks events'
  end
end