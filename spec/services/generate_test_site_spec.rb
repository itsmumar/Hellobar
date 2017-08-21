describe GenerateTestSite do
  let(:site) { create(:site) }

  before do
    allow_any_instance_of(Site).to receive(:statistics).and_return(SiteStatistics.new)
  end

  describe '#initialize' do
    it 'finds the site' do
      generator = described_class.new(site.id)

      expect(generator.site).to eq(site)
    end

    it 'takes a full path' do
      full_path = '/Users/hello/bar.html'

      generator = described_class.new(site.id, full_path: full_path)

      expect(generator.full_path).to eq(full_path)
    end

    it 'has a nil full_path when neither full_path or directory are set' do
      generator = described_class.new(site.id)

      expect(generator.full_path).to be_nil
    end

    context 'when directory is set' do
      it 'generates a full path in that directory' do
        directory = Rails.root.join('spec', 'tmp')

        generator = described_class.new(site.id, directory: directory)

        expect(generator.full_path.to_s).to be_starts_with(directory.to_s)
      end

      it 'generates an html file' do
        directory = Rails.root.join('spec', 'tmp')

        generator = described_class.new(site.id, directory: directory)

        expect(File.extname(generator.full_path.to_s)).to eq('.html')
      end
    end
  end

  describe '#generate_html' do
    before { expect(RenderStaticScript).to receive_service_call.with(site, compress: false).and_return('script content') }

    it "includes the site's script content", :freeze do
      generator = described_class.new(site.id)

      html = generator.generate_html

      expect(html).to include('script content')
    end
  end

  describe '#generate_file' do
    it 'creates a file at full path' do
      expect(RenderStaticScript).to receive_service_call.with(site, compress: false)
      path = generate_path
      generator = described_class.new(site.id, full_path: path)

      generator.generate_file

      expect(File.exist?(path)).to be_truthy

      File.delete(path)
    end

    it 'creates a file with the generated html' do
      path = generate_path
      generator = described_class.new(site.id, full_path: path)
      allow(generator).to receive(:generate_html)

      generator.generate_file

      expect(generator).to have_received(:generate_html)

      File.delete(path)
    end

    def generate_path
      dir = Rails.root.join('spec', 'tmp')
      Dir.mkdir(dir) unless File.directory?(dir)
      dir.join("#{ SecureRandom.hex }.html")
    end
  end
end
