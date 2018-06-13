describe HellobarModules do
  let(:version) { File.read('.hellobar-modules-version').chomp }

  describe '.version' do
    it 'reads version from .hellobar-modules-version' do
      expect(HellobarModules.version).to eql version
    end
  end

  describe '.filename' do
    specify do
      expect(HellobarModules.filename).to eql "modules-v#{ version }.js"
    end
  end

  describe '.local_modules_url' do
    let(:url) { 'http://localhost:9090/modules.bundle.js' }

    before do
      allow(Settings)
        .to receive(:local_modules_url)
        .and_return url

      allow(HTTParty)
        .to receive(:get)
        .with(Settings.local_modules_url)
        .and_return(double(success?: true))
    end

    specify do
      expect(HellobarModules.local_modules_url).to eql url
    end
  end

  describe '.bump!' do
    let(:next_version) { version.to_i.next }

    specify do
      expect(File)
        .to receive(:write)
        .with('.hellobar-modules-version', next_version)

      HellobarModules.bump!
    end
  end
end
