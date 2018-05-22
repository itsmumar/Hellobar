feature 'Content upgrades', :js do
  given!(:content_upgrade_settings) { create(:content_upgrade_settings, offer_headline: 'Offer 123') }
  given!(:content_upgrade) { create(:content_upgrade, content_upgrade_settings: content_upgrade_settings) }
  given(:site) { content_upgrade.site }
  given!(:subscription) { create(:subscription, :pro_managed, site: site) }

  before do
    allow_any_instance_of(StaticScriptModel).to receive(:pro_secret).and_return 'random'
  end

  scenario 'inserting a single content upgrade' do
    visit test_site_path(id: site.id)

    expect(page).to have_selector '#content-upgrade-container'

    within '#content-upgrade-container' do
      expect(page).to have_selector 'p.hb-cu-offer'
      expect(find('.hb-cu-modal-container', visible: false)).not_to be_visible

      find('p.hb-cu-offer').click

      expect(find('.hb-cu-modal-container')).to be_visible
    end
  end

  scenario 'running an A/B test for content upgrades' do
    create(
      :content_upgrade,
      rule: content_upgrade.rule,
      content_upgrade_settings: create(:content_upgrade_settings, offer_headline: 'Test 123')
    )

    create(
      :content_upgrade,
      rule: content_upgrade.rule,
      content_upgrade_settings: create(:content_upgrade_settings, offer_headline: 'Test 456')
    )

    create(
      :content_upgrade,
      rule: content_upgrade.rule,
      content_upgrade_settings: create(:content_upgrade_settings, offer_headline: 'Test 789')
    )

    visit test_site_path(id: site.id)

    expect(page).to have_selector '#content-upgrade-ab-test-container'

    within '#content-upgrade-ab-test-container' do
      expect(page).to have_selector 'p.hb-cu-offer'
      expect(find('.hb-cu-modal-container', visible: false)).to_not be_visible

      possible_headlines = site.site_elements.active_content_upgrades.map(&:offer_headline)
      expect(possible_headlines).to include(find('p.hb-cu-offer').text)

      find('p.hb-cu-offer').click

      expect(find('.hb-cu-modal-container')).to be_visible
    end
  end
end
