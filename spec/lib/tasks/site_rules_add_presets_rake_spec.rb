require 'rake'
load 'lib/tasks/site.rake'

describe 'site:rules:add_presets' do
  include_context 'rake'

  let(:site_with_presets) { create(:site) }
  let(:site_without_presets) { create(:site) }

  before do
    site_with_presets.create_default_rules
    site_without_presets.rules << site_without_presets.rules.defaults[0]
  end

  it 'should add the Mobile and Homepage Visitors presets' do
    perform!
    expect(site_without_presets.reload.rules.size).to eq(3)
  end

  it 'should not add presets to sites that already have them' do
    perform!
    expect(site_with_presets.rules.size).to eq(3)
  end

  it 'should not regenerate site scripts' do
    expect_any_instance_of(Site).not_to receive(:generate_static_assets)
    expect_any_instance_of(Site).not_to receive(:delay).with(:generate_static_assets, anything)
    perform!
  end

  private

  def perform!
    subject.invoke
    site_with_presets.reload
    site_without_presets.reload
  end
end
