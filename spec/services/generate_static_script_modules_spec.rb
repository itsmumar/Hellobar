describe GenerateStaticScriptModules do
  let(:script_content) { 'script content' }
  let(:compressed_script) { 'compressed script' }
  let(:service) { described_class.new }

  before do
    allow(StaticScriptAssets).to receive(:render_compressed).and_return(compressed_script)
    allow(StaticScriptAssets).to receive(:render).and_return(script_content)
    allow(StaticScriptAssets).to receive(:compile)
  end

  shared_examples 'common' do
    it 'compiles modules.js' do
      expect(StaticScriptAssets).to receive(:compile).with('modules.js')
      service.call
    end
  end

  context 'when store locally' do
    let(:file) { instance_double(File, 'file') }

    before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

    include_examples 'common'

    it 'creates file in public/generated_scripts' do
      expect(file).to receive(:puts).with(script_content)
      expect(File).to receive(:open).with(pathname_ending_with('public/generated_scripts/modules-hexdigest.js'), 'w').and_yield(file)
      service.call
    end
  end

  context 'when store remotly' do
    before do
      allow(Settings).to receive(:store_site_scripts_locally).and_return(false)
      allow(UploadToS3).to receive_message_chain(:new, :call)
    end

    include_examples 'common'

    it 'uploads script to S3' do
      expect(UploadToS3)
        .to receive_service_call
        .with('modules-hexdigest.js', compressed_script, cache: 1.year)

      service.call
    end
  end
end
