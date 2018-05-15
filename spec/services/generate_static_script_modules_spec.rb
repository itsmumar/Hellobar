describe GenerateStaticScriptModules do
  let(:script_content) { 'script content' }
  let(:compressed_script) { 'compressed script' }
  let(:service) { described_class.new }
  let(:file) { instance_double(File, 'file') }
  let(:digest_path) { StaticScriptAssets.digest_path('modules.js') }

  before do
    allow(StaticScriptAssets).to receive(:render_compressed).and_return(compressed_script)
    allow(StaticScriptAssets).to receive(:render).and_return(script_content)
    allow(StaticScriptAssets).to receive(:compile_if_missed)

    allow(File)
      .to receive(:write)
      .with(
        pathname_ending_with("public/generated_scripts/#{ digest_path }"),
        script_content
      )
  end

  shared_examples 'common' do
    it 'compiles modules.js' do
      expect(StaticScriptAssets).to receive(:compile_if_missed).with('modules.js')
      service.call
    end
  end

  context 'when stored locally' do
    before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

    include_examples 'common'

    it 'creates file in public/generated_scripts' do
      expect(File)
        .to receive(:write)
        .with(
          pathname_ending_with("public/generated_scripts/#{ digest_path }"),
          script_content
        )

      service.call
    end
  end

  context 'when stored remotely' do
    before do
      allow(Settings).to receive(:store_site_scripts_locally).and_return(false)
      allow(UploadToS3).to receive_message_chain(:new, :call)
    end

    include_examples 'common'

    it 'uploads script to S3' do
      expect(UploadToS3)
        .to receive_service_call
        .with(a_string_matching('modules-'), compressed_script, cache: 1.year)

      service.call
    end
  end
end
