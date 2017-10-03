require 'integration_helper'

feature 'Users can select a design theme for SiteElements', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, user: user) }
  given(:subtype) { 'Modal' }
  given(:theme_id) { 'blue-autumn' }
  given(:themes) { Theme.where(type: 'generic') }
  given(:theme) { themes.detect { |theme| theme.id == theme_id } }
  given(:url) { new_site_site_element_path(site) + '/#/styles' }

  background do
    login user
    visit url
  end

  scenario 'selecting a theme updates the color palette in the UI' do
    find('a', text: 'CHANGE TYPE').click
    find('h6', text: /#{ subtype }/i).click

    expect(page).to have_content 'Themes'

    # select the theme
    within "div[data-theme-id='#{ theme_id }']" do
      find('a', visible: false).trigger 'click'
    end

    click_on 'Content'

    expect(page).to have_content 'DESIGN & CONTENT'

    background_color = theme.defaults[subtype]['background_color']

    # verify the `background_color`
    expect(first('.color-select-block input').value).to match(/#{ background_color }/i)
  end

  context 'with Bar type' do
    given(:subtype) { 'Bar' }
    given(:site) { create(:site, user: user, elements: [:email]) }

    scenario '"Pushes page down" is ON by default' do
      find('a', text: 'CHANGE TYPE').click
      find('h6', text: /#{ subtype }/i).click
      expect(first('.toggle-pushing-page-down')).to have_selector '.toggle-switch.is-selected'
    end

    context 'while editing' do
      given(:url) { edit_site_site_element_path(site, site.site_elements.first) + '/#/style/bar' }

      background do
        site.site_elements.first.update pushes_page_down: false
      end

      scenario 'does not override existing value for "Pushes page down"' do
        visit url
        expect(first('.toggle-pushing-page-down')).not_to have_selector '.toggle-switch.is-selected'
      end
    end
  end

  context 'with Modal type' do
    context 'with autodetect theme' do
      before do
        allow_any_instance_of(StaticScriptModel).to receive(:pro_secret).and_return 'random'
      end

      given(:url) { new_site_site_element_path(site) + '/#/goals' }

      scenario 'displays image in preview' do
        visit url
        click_on 'Next'
        find('a', text: 'CHANGE TYPE').click
        find('h6', text: 'Modal').click
        first('.autodetection-button').click
        click_on 'Next'
        click_on 'Image'
        execute_script('$(".dz-hidden-input").attr("id", "dz-image").removeAttr("style")') # make the input visible
        attach_file 'dz-image', generate(:image)

        page.has_xpath?('.//iframe[@id="random-container"]') # force capybara to wait until iframe is loaded
        sleep 2
        within_frame 'random-container-0' do
          expect(find('.uploaded-image')[:src]).to eql ImageUpload.last.url
        end
      end
    end
  end
end
