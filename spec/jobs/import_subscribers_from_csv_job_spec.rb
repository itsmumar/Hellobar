describe ImportSubscribersFromCsvJob do
  let(:job) { described_class }
  let(:csv_upload) { create :csv_upload }
  let(:csv) { Paperclip.io_adapters.for(csv_upload.csv) }

  describe '#perform' do
    let(:perform) { job.new.perform(csv_upload) }

    it 'calls ImportSubscribersFromCsv' do
      expect(ImportSubscribersFromCsv)
        .to receive_service_call
        .with(instance_of(Paperclip::AttachmentAdapter), csv_upload.contact_list)
      perform
    end
  end
end
