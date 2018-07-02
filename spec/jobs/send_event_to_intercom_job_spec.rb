describe SendEventToIntercomJob do
  let(:job) { described_class }

  describe '#perform' do
    let(:user) { create :user }
    let(:site) { create :site }
    let(:perform) { job.perform_now('signed_up', user: user, site: site) }
    let(:analytics) { instance_double AnalyticsProvider }

    before do
      allow(analytics).to receive(:fire_event)
      allow(AnalyticsProvider).to receive(:new).and_return(analytics)
      allow_any_instance_of(IntercomGateway).to receive(:create_user)
    end

    it 'uses IntercomAnalyticsAdapter' do
      expect(AnalyticsProvider)
        .to receive(:new)
        .with(instance_of(IntercomAnalyticsAdapter))

      perform
    end

    it 'calls #fire_event' do
      expect(analytics)
        .to receive(:fire_event)
        .with('signed_up', user: user, site: site)

      perform
    end

    context 'when Intercom::ResourceNotFound is raised' do
      let(:message) { 'Tag Not Found' }

      before do
        allow(analytics)
          .to receive(:fire_event)
          .with('signed_up', anything)
          .twice
          .and_raise(Intercom::ResourceNotFound, message)
      end

      it 'raise error' do
        expect { perform }.to raise_error(Intercom::ResourceNotFound)
      end

      context 'with message "User Not Found"' do
        let(:message) { 'User Not Found' }

        it 'calls IntercomGateway#create_user and raise error' do
          expect_any_instance_of(IntercomGateway).to receive :create_user
          expect { perform }.to raise_error(Intercom::ResourceNotFound)
        end
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later('event')

      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
