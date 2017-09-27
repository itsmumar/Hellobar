describe DestroySite do
  describe '#call', :freeze do
    it 'marks the record as deleted and blanks out the site script' do
      site = create :site

      expect(GenerateAndStoreStaticScript).to receive_service_call
        .with site, script_content: ''

      DestroySite.new(site).call

      expect(site).to be_deleted
      expect(site.deleted_at).to eq Time.current
    end
  end
end
