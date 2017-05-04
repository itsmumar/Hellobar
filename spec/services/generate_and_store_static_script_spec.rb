describe GenerateAndStoreStaticScript do
  let(:site) { create(:site, :with_user, :with_rule) }
  let(:mock_storage) { double('asset_storage') }
  let(:script_content) { 'script content' }

  let(:service) { described_class.new(site) }

  around do |ex|
    Hellobar::Settings[:store_site_scripts_locally] = false
    ex.call
    Hellobar::Settings[:store_site_scripts_locally] = true
  end

  before do
    allow(Hello::AssetStorage).to receive(:new).and_return(mock_storage)
    allow_any_instance_of(RenderStaticScript).to receive(:call).and_return(script_content)
  end

  it 'generates and uploads the script content for a site' do
    expect(mock_storage).to receive(:create_or_update_file_with_contents).with(site.script_name, script_content)
    service.call
  end

  context 'with wordpress bar' do
    let(:wordpress_bar) { create(:site_element, site: site, wordpress_bar_id: 123) }
    let(:user) { create(:user, site: site, wordpress_user_id: 456) }
    let!(:filename) { "#{ user.wordpress_user_id }_#{ wordpress_bar.wordpress_bar_id }.js" }

    it 'generates scripts for each wordpress bar' do
      expect(mock_storage).to receive(:create_or_update_file_with_contents).with(site.script_name, script_content).ordered
      expect(mock_storage).to receive(:create_or_update_file_with_contents).with(filename, script_content).ordered
      service.call
    end
  end

  context 'when store locally' do
    before { Hellobar::Settings[:store_site_scripts_locally] = true }

    it 'does not compress script' do
      expect(StaticScriptAssets).not_to receive(:compress)
      service.call
    end
  end
end
