describe ExportSubscribersJob do
  let(:job) { described_class }
  let(:contact_list) { create :contact_list }
  let(:subscribers) { [Contact.new(email: 'email@example.com', name: 'name', subscribed_at: Time.current)] }
  let(:user) { create :user }

  describe '#perform' do
    let(:perform) { job.new.perform(user, contact_list) }

    it 'calls ContactsMailer#csv_export' do
      expect(FetchSubscribers).to receive_service_call.and_return(items: subscribers)
      expect(ContactsMailer).to receive(:csv_export).and_call_original
      perform
    end
  end

  describe '.perform_later' do
    it 'adds the job to the queue Settings.low_priority_queue' do
      job.perform_later(user, contact_list)
      expect(enqueued_jobs.last[:queue]).to eq 'hb3_test'
    end
  end
end
