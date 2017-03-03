require 'integration_helper'

feature 'Users can select a design theme for SiteElements', :js do
  given(:subtype) { 'Modal' }
  given(:theme_id) { 'blue-autumn' }
  given(:themes) { Theme.where(type: 'generic') }
  given(:theme) { themes.detect { |theme| theme.id == theme_id } }

  before do
    @user = login
  end

  scenario 'selecting a theme updates the color palette in the UI' do
    visit new_site_site_element_path(@user.sites.first) + '/#/style'

    find('a', text: /#{ subtype }/i).click

    expect(page).to have_content 'Themes'

    # select the theme
    within "div[data-theme-id='#{theme_id}']" do
      find('a', visible: false).trigger 'click'
    end

    click_on 'Content'

    expect(page).to have_content 'DESIGN & CONTENT'

    background_color = theme.defaults[subtype]['background_color']

    # verify the `background_color`
    expect(first('.color-select-block input').value).to match(/#{ background_color }/i)
  end
end
