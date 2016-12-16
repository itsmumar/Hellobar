require 'integration_helper'

feature "Users can select design themes for SiteElements", js: true do
  before do
    @user = login
    visit new_site_site_element_path(@user.sites.first) + "/#/style"
    page.find('a', text: /#{subtype}/i).click
  end
  let(:subtype)            { "Modal" }
  let(:themes)             { Theme.where(type: "generic") }
  let(:default_theme)      { Theme.find('classic') }
  let(:themes_with_images) { [Theme.find('marigold'), Theme.find('french-rose')] }

  scenario "Selecting a theme updates the color palette" do
    # We don't show `classy` theme on UI.
    # `classic` theme's defaults gets updated according to target site color themes.
    # So, ignoring these themes in test suite.
    themes.each { |theme| themes.delete(theme) if theme.id == "classy" || theme.id == 'classic' }

    (themes).each do |theme|
      # close annoucement if exists
      announcement_container = page.first(".announcement-container")
      if announcement_container
        within(announcement_container) do
          find('a.close-announcement').click
        end
      end

      # select the theme
      page.find("div[data-theme-id='#{theme.id}']", text: theme.name).click
      page.find(".icon-content").click

      background_color = theme.defaults[subtype]["background_color"]
      background_color_input = page.find("label", text: "Background Color").first(:xpath,".//..").first("input")

      # verify the `background_color`
      expect(background_color_input.value).to match(/#{background_color}/i)

      # reset current theme settings
      page.find(".icon-style").click
      page.find("a", text: '[change theme]').click
      page.find("a", text: 'Yes, Change The Theme').click
    end
  end
end
