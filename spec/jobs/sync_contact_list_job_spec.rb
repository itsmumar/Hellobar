describe SyncContactListJob do
  let(:job) { described_class }
  let(:contact_list) { create :contact_list }

  describe '#perform' do
    let(:perform) { job.new.perform(contact_list) }

    it 'calls on contact_list.sync_all!' do
      expect(contact_list).to receive(:sync_all!)
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.main_queue' do
      job.perform_later(contact_list)
      expect(enqueued_jobs.last[:queue]).to eq Settings.main_queue
    end
  end
end
