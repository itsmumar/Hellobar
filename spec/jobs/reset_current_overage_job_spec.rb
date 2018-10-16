describe ResetCurrentOverageJob do
  let(:job) { described_class }
  let(:site) { create :site }
  let(:views) { { site.id => 999 } }

  before do
    allow(FetchTotalViewsForMonth)
      .to receive_service_call.and_return views
  end

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'calls FetchTotalViewsForMonth' do
      expect(FetchTotalViewsForMonth)
        .to receive_service_call
        .with([site])
        .and_return(views)

      perform
    end

    context 'when number of views >= views limit' do
      before { allow(site).to receive(:views_limit).and_return(1) }

      it 'calls HandleOverageSite' do
        expect(HandleOverageSite)
          .to receive_service_call
          .with(site, views[site.id], site.views_limit)

        perform
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.main_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test'
    end
  end
end
