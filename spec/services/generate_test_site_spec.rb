describe GenerateTestSite do
  let(:site) { create(:site) }
  let(:service) { GenerateTestSite.new(site.id) }
  let(:site_html_file) { service.call }

  before do
    allow_any_instance_of(Site).to receive(:statistics).and_return(SiteStatistics.new)
    expect(GenerateAndStoreStaticScript)
      .to receive_service_call
      .with(site, path: 'test_site.js')
  end

  after do
    File.delete(site_html_file) if File.exist?(site_html_file)
  end

  describe '#call' do
    before do
      allow_any_instance_of(GenerateTestSite)
        .to receive(:generate_html)
        .and_return('html')
    end

    it 'renders the site\'s script content', :freeze do
      expect(File.read(site_html_file)).to eql 'html'
    end

    it 'creates a file at full path' do
      expect(File.exist?(site_html_file)).to be_truthy
    end

    context 'with directory option' do
      let(:directory) { Rails.root.join('tmp') }
      let(:service) { GenerateTestSite.new(site.id, directory: directory) }

      it 'creates a file at directory' do
        expect(site_html_file).to be_exist
        expect(site_html_file.to_s).to start_with directory.to_s
      end
    end
  end
end
