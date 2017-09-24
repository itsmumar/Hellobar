describe DestroySite do
  let(:site) { create :site }
  let(:service) { DestroySite.new(site) }

  describe '#call', :freeze do
    let(:mock_upload_to_s3) { double(:upload_to_s3) }

    it 'blanks-out the site script when destroyed' do
      expect(site.script).to receive(:destroy)
      service.call
    end

    it 'marks the record as deleted' do
      expect(GenerateAndStoreStaticScript)
        .to receive_service_call.with(site, script_content: '')

      service.call

      expect(site).to be_deleted
      expect(site.deleted_at).to eq Time.current
    end
  end
end
