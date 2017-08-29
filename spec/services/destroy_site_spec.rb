describe DestroySite do
  let(:site) { create :site }
  let(:service) { DestroySite.new(site) }

  describe '#call', :freeze do
    let(:mock_upload_to_s3) { double(:upload_to_s3) }

    before do
      allow(Settings).to receive(:store_site_scripts_locally).and_return false
      allow(UploadToS3).to receive(:new).and_return(mock_upload_to_s3)
      allow(mock_upload_to_s3).to receive(:call).with(no_args)
    end

    it 'blanks-out the site script when destroyed' do
      service.call
      expect(UploadToS3).to have_received(:new).with(site.script_name, '')
    end

    it 'marks the record as deleted' do
      service.call

      expect(site).to be_deleted
      expect(site.deleted_at).to eq Time.current
    end
  end
end
