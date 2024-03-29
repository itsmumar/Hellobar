describe DownloadHellobarModules do
  let(:filename) { HellobarModules.filename }
  let(:script_content) { 'script content' }

  let(:file) { double(File) }

  let(:path) { File.join(StaticScript::SCRIPTS_LOCAL_FOLDER, filename) }
  let(:local_path) { Rails.root.join(path) }
  let(:url) { "https://#{ Settings.script_cdn_url }/#{ filename }" }

  let(:response) { double(to_s: script_content, success?: true) }
  let(:service) { described_class.new }

  before do
    DownloadHellobarModules.logger = nil

    allow(Rails)
      .to receive_message_chain(:root, :join)
      .with('public', 'generated_scripts', filename)
      .and_return(local_path)

    allow(HTTParty)
      .to receive(:get)
      .with(url)
      .and_return(response)
  end

  context 'when not in test env and file exists' do
    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(local_path).to receive(:exist?).and_return(true)
    end

    it 'does nothing' do
      expect(File).not_to receive(:open)
      expect(HTTParty).not_to receive(:get)
      service.call
    end
  end

  context 'when file does not exist' do
    before do
      allow(local_path).to receive(:exist?).and_return(false)
    end

    it 'downloads and stores file in public/generated_scripts' do
      expect(file).to receive(:puts).with(script_content)
      expect(File)
        .to receive(:open)
        .with(pathname_ending_with(path), 'wb')
        .and_yield(file)

      expect(HTTParty)
        .to receive(:get)
        .with(url)
        .and_return(response)

      service.call
    end
  end

  context 'when file is not found' do
    before do
      allow(local_path).to receive(:exist?).and_return(false)
    end

    let(:response) { double(to_s: script_content, success?: false) }

    it 'raises ScriptNotFound error' do
      expect { service.call }
        .to raise_error(
          DownloadHellobarModules::ScriptNotFound,
          "hellobar script version #{ url.inspect } couldn't be found"
        )
    end
  end
end
