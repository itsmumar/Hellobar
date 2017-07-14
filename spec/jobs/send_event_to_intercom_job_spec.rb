describe SendEventToIntercomJob do
  let(:job) { described_class }

  describe '#perform' do
    let(:user) { create :user }
    let(:site) { create :site }
    let(:perform) { job.perform_now('created_site', user: user, site: site) }
    let(:analytics) { IntercomAnalytics.new }

    before { allow(IntercomAnalytics).to receive(:new).and_return(analytics) }

    it 'calls IntercomAnalytics#fire_event' do
      expect(analytics).to receive(:fire_event).with('created_site', user: user, site: site)
      perform
    end

    context 'when Intercom::ResourceNotFound is raised' do

      before do
        expect(analytics).to receive(:track).once.and_raise(Intercom::ResourceNotFound, 'User Not Found')
      end

      it 'calls IntercomAnalytics#create_user and retries the job' do
        expect(analytics).to receive(:created_user).with(user: user).once
        expect { perform }.to have_enqueued_job(SendEventToIntercomJob)
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
