describe ExportSubscribersJob do
  let(:job) { described_class }
  let(:user) { create :user }
  let(:contact_list) { create :contact_list }

  let(:csv) do
    <<~CSV
      Email,Fields,Subscribed At
      email1@example.com,name1,#{ Time.current }
      email2@example.com,name2,#{ Time.current }
      email3@example.com,name3,#{ Time.current }
    CSV
  end

  describe '#perform' do
    let(:perform) { job.new.perform(user, contact_list) }

    it 'calls ContactsMailer#csv_export' do
      expect(ExportSubscribers).to receive_service_call.and_return(csv)
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
