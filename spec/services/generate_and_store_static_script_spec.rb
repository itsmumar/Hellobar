describe GenerateAndStoreStaticScript do
  let(:site) { create(:site, :with_user, :with_rule) }
  let(:mock_upload_to_s3) { double(:upload_to_s3, call: true) }
  let(:script_content) { 'script content' }

  let(:service) { described_class.new(site) }

  before do
    allow(Settings).to receive(:store_site_scripts_locally).and_return false
    allow_any_instance_of(RenderStaticScript).to receive(:call).and_return(script_content)
    expect(GenerateStaticScriptModules).to receive_service_call
  end

  it 'generates and uploads the script content for a site' do
    allow(UploadToS3).to receive(:new).with(site.script_name, script_content).and_return(mock_upload_to_s3)

    service.call
  end

  context 'with wordpress bar' do
    let(:wordpress_bar) { create(:site_element, site: site, wordpress_bar_id: 123) }
    let(:user) { create(:user, site: site, wordpress_user_id: 456) }
    let(:mock_wordpress_upload_to_s3) { double(:upload_wordpress_to_s3, call: true) }
    let!(:filename) { "#{ user.wordpress_user_id }_#{ wordpress_bar.wordpress_bar_id }.js" }

    it 'generates scripts for each wordpress bar' do
      expect(UploadToS3).to receive(:new).with(site.script_name, script_content).and_return(mock_upload_to_s3)
      expect(UploadToS3).to receive(:new).with(filename, script_content).and_return(mock_wordpress_upload_to_s3)

      service.call
    end
  end

  context 'when store locally' do
    let(:file) { double('file') }
    before { allow(Analytics).to receive(:track) }
    before { allow(Settings).to receive(:store_site_scripts_locally).and_return true }

    it 'does not compress script' do
      expect(StaticScriptAssets).not_to receive(:with_js_compressor)
      service.call
    end

    it 'creates file in public/generated_scripts' do
      expect(file).to receive(:puts).with(script_content)
      expect(File).to receive(:open).and_yield(file)
      service.call
    end
  end

  context 'when store remotly' do
    before { allow(Settings).to receive(:store_site_scripts_locally).and_return false }

    it 'uploads script to S3' do
      expect(UploadToS3).to receive_service_call.with(site.script_name, script_content)
      service.call
    end
  end
end
