describe CheckNumberOfViewsForSites do
  let!(:site) { create :site }
  let(:sites) { Site.all }
  let(:service) { CheckNumberOfViewsForSites.new(sites) }
  let(:report) { BillingViewsReport.new(1) }
  let(:number_of_views) { 1000 }

  before do
    allow(BillingViewsReport).to receive(:new).and_return report
    allow(report).to receive(:start)
    allow(report).to receive(:finish)
    allow(report).to receive(:count)
    allow(report).to receive(:limit_exceeded)
    allow(FetchTotalViewsForMonth)
      .to receive_service_call.and_return(Hash[site.id => number_of_views])

    allow(HandleOverageSite).to receive_service_call
  end

  it 'calls report' do
    service.call
    expect(report).to have_received(:start)
    expect(report).to have_received(:count).exactly(1).times.with(number_of_views)
    expect(report).to have_received(:finish)
  end

  context 'when limit exceeded' do
    let(:number_of_views) { site.views_limit + 1 }

    it 'calls report.limit_exceeded' do
      service.call
      expect(report)
        .to have_received(:limit_exceeded)
        .with(site, number_of_views, site.views_limit)
    end

    it 'calls HandleOverageSite' do
      perform_enqueued_jobs do
        expect(HandleOverageSite).to receive_service_call
        service.call
      end
    end
  end

  context 'when exception is raised' do
    let(:error) { StandardError.new('OOPS!') }

    before { expect(report).to receive(:start).and_raise(error) }

    it 'stops processing' do
      expect(report).to receive(:interrupt).with(error)
      expect(Raven).to receive(:capture_exception).with(error)
      expect { service.call }.to raise_error error
    end
  end
end
