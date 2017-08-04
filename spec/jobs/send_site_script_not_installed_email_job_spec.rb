describe SendSiteScriptNotInstalledEmailJob do
  let(:job) { described_class }
  let(:owner) { create :user }
  let(:admin) { create :user }
  let(:site) { create :site, user: owner }

  let(:mail) { double(deliver_now: true) }

  before { site.admins << admin }

  describe '#perform' do
    let(:perform) { job.new.perform(site) }

    it 'sends not installed email for all admins and owners' do
      [admin, owner].each do |user|
        expect(SiteMailer).to receive(:site_script_not_installed).with(site, user).and_return(mail)
      end
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(site)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test_lowpriority'
    end
  end
end
