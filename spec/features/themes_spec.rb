require 'integration_helper'

feature "Users can select design themes for SiteElements", js: true do
  given(:subtype) { "Modal" }
  given(:themes) { Theme.where(type: "generic") }
  given(:default_theme) { Theme.find('classic') }
  given(:themes_with_images) { [Theme.find('marigold'), Theme.find('french-rose')] }

  before do
    @user = login

    visit new_site_site_element_path(@user.sites.first) + "/#/style"

    find('a', text: /#{subtype}/i).click
  end

  scenario "Selecting a theme updates the color palette" do
    # We don't show `classy` theme on UI.
    # `classic` theme's defaults gets updated according to target site color themes.
    # So, ignoring these themes in test suite.
    themes.each do |theme|
      themes.delete(theme) if theme.id == "classy" || theme.id == 'classic'
    end

    themes.each do |theme|
      # close annoucement if exists
      announcement_container = first(".announcement-container")

      if announcement_container
        within(announcement_container) do
          find('a.close-announcement').click
        end
      end

      # select the theme
      within "div[data-theme-id='#{theme.id}']" do
        find('a', visible: false).trigger 'click'
      end

      find(".icon-content").click

      background_color = theme.defaults[subtype]["background_color"]

      # verify the `background_color`
      expect(first('.color-select-block input').value).to match(/#{ background_color }/i)

      # reset current theme settings
      find(".icon-style").click
      find("a", text: '[change theme]').click
      find("a", text: 'Yes, Change The Theme').click
    end
  end
end
