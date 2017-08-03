describe SendWeeklyDigestJob do
  let(:job) { described_class }
  let(:owner) { create :user }
  let(:admin) { create :user }
  let(:site) { create :site, user: owner }
  let(:beginning_of_week) { EmailDigestHelper.last_week.first }

  let(:mail) { double(deliver_now: true) }

  before { site.admins << admin }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    before do
      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, days_limit: 14)
        .and_return(statistics)
    end

    context 'when site has views' do
      let(:statistics) { create :site_statistics, views: [1], first_date: beginning_of_week }

      it 'sends weekly digest for all admins and owners' do
        [admin, owner].each do |user|
          expect(SiteMailer).to receive(:weekly_digest).with(site, user).and_return(mail)
        end
        perform
      end
    end

    context 'when site has no views' do
      let(:statistics) { create :site_statistics, views: [0], first_date: beginning_of_week }

      it 'does not call SendEmailDigest' do
        expect(SiteMailer).not_to receive(:weekly_digest)
        perform
      end
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
