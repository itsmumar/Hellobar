describe GenerateTestSite do
  let(:site) { create(:site) }
  let(:path) { generate_path }
  let(:service) { GenerateTestSite.new(site.id, full_path: path) }

  def generate_path
    dir = Rails.root.join('spec', 'tmp')
    Dir.mkdir(dir) unless File.directory?(dir)
    dir.join("#{ SecureRandom.hex }.html")
  end

  before do
    allow_any_instance_of(Site).to receive(:statistics).and_return(SiteStatistics.new)
    expect(GenerateAndStoreStaticScript)
      .to receive_service_call
      .with(site, path: 'test_site.js')
  end

  after do
    File.delete(path) if File.exist?(path)
  end

  describe '#call' do
    before do
      allow_any_instance_of(GenerateTestSite)
        .to receive(:generate_html)
        .and_return('html')
    end

    it 'renders the site\'s script content', :freeze do
      service.call
      expect(File.read(path)).to eql 'html'
    end

    it 'creates a file at full path' do
      service.call

      expect(File.exist?(path)).to be_truthy
    end

    context 'with directory option' do
      before { allow(SecureRandom).to receive(:hex).and_return 'hex-digest' }
      after { directory.join('hex-digest.html').delete }

      let(:directory) { Rails.root.join('tmp') }

      it 'creates a file at directory' do
        GenerateTestSite.new(site.id, directory: directory).call
        expect(directory.join('hex-digest.html')).to be_exist
      end
    end
  end
end
