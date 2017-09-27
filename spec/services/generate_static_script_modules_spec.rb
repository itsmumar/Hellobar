describe GenerateStaticScriptModules do
  let(:script_content) { 'script content' }
  let(:compressed_script) { 'compressed script' }
  let(:service) { described_class.new }

  before do
    allow(Settings).to receive(:store_site_scripts_locally).and_return false
    allow(StaticScriptAssets).to receive(:render_compressed).and_return(compressed_script)
    allow(StaticScriptAssets).to receive(:render).and_return(script_content)
  end

  it 'generates and uploads the modules content' do
    expect(UploadToS3)
      .to receive_service_call
      .with('modules-hexdigest.js', compressed_script, cache: 1.year)

    service.call
  end

  context 'when store locally' do
    let(:file) { double('file') }
    before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

    it 'creates file in public/generated_scripts' do
      expect(file).to receive(:puts).with(script_content)
      expect(File).to receive(:open).and_yield(file)
      service.call
    end
  end

  context 'when store remotly' do
    before { allow(Settings).to receive(:store_site_scripts_locally).and_return false }

    it 'uploads script to S3' do
      expect(UploadToS3)
        .to receive_service_call
        .with('modules-hexdigest.js', compressed_script, cache: 1.year)

      service.call
    end
  end
end
