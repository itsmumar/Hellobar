require 'integration_helper'

feature "Users can select design themes for SiteElements", js: true do
  before do
    @user = login
    visit new_site_site_element_path(@user.sites.first, skip_interstitial: true, anchor: "style")
    page.find('a', text: /#{subtype}/i).click
    page.find('a', text: 'Next').click
  end
  let(:subtype)            { "Modal" }
  let(:first_select_input) { page.first("select") }
  let(:themes)             { Theme.all }
  let(:theme_options)      { themes.collect{|t| t.name} }
  let(:default_theme)      { Theme.find('classic') }
  let(:themes_with_images) { [Theme.find('marigold'), Theme.find('french-rose')] }

  scenario "Selecting a theme updates the color palette" do
    expect(page).to have_select(first_select_input["id"], :options => theme_options, :selected => default_theme.name)

    (themes).each do |theme|
      first_select_input.find(:option, theme.name).select_option

      background_color = theme.defaults[subtype]["background_color"]
      background_color_input = page.find("label", text: "Background Color").first(:xpath,".//..").first("input")

      expect(background_color_input.value).to match(/#{background_color}/i)
    end
  end
end
