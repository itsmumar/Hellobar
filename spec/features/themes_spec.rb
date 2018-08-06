feature 'Users can select a design theme for SiteElements', :js do
  given(:user) { create :user, :with_site }
  given(:site) { user.sites.first }
  given(:subtype) { 'Modal' }
  given(:theme_id) { 'blue-autumn' }
  given(:themes) { Theme.where(type: 'generic') }
  given(:theme) { themes.detect { |theme| theme.id == theme_id } }
  given(:url) { new_site_site_element_path(site) + '/#/goal' }
  given(:image) { Rails.root.join('spec', 'fixtures', 'images', 'coupon.png').to_s }

  background do
    sign_in user

    visit url
    find('h6', text: 'Collect emails').click
    find('.step-links__item .caption', text: 'Type').click
  end

  scenario 'selecting a theme updates the color palette in the UI' do
    find('h6', text: /#{ subtype }/i).click
    find('.step-links__item .caption', text: 'Design').click
    find('.design__template-button', text: 'Change template').click

    find("div[data-theme-id='#{ theme_id }']").click
    find('.collapse', text: 'Modal Styling').click

    background_color = theme.defaults[subtype]['background_color']

    # verify the `background_color`
    expect(find('.panel-input', text: 'Color').find('input').value)
      .to match(/#{ background_color }/i)
  end

  context 'with Bar type' do
    given(:subtype) { 'Bar' }
    given(:site) { create(:site, user: user, elements: [:email]) }

    scenario '"Pushes page down" is ON by default' do
      find('h6', text: /#{ subtype }/i).click
      find('.step-links__item .caption', text: 'Settings').click
      expect(first('.toggle-pushing-page-down')).to have_selector '.toggle-switch'
    end

    context 'while editing' do
      background do
        site.site_elements.first.update pushes_page_down: false
      end

      scenario 'does not override existing value for "Pushes page down"' do
        visit edit_site_site_element_path(site, site.site_elements.first)
        find('.step-links__item .caption', text: 'Settings').click
        expect(first('.toggle-pushing-page-down')).to have_selector '.toggle-switch.is-selected'
      end
    end
  end

  context 'with Modal type' do
    context 'with autodetect theme' do
      before do
        allow_any_instance_of(StaticScriptModel).to receive(:pro_secret).and_return 'random'
      end

      scenario 'displays image in preview' do
        find('h6', text: 'Modal').click
        find('.step-links__item .caption', text: 'Design').click
        find('.collapse', text: 'Image').click

        execute_script('$(".dz-hidden-input").attr("id", "dz-image").removeAttr("style")') # make the input visible
        attach_file 'dz-image', image

        page.has_xpath?('.//iframe[@id="random-container"]') # force capybara to wait until iframe is loaded

        sleep 2

        within_frame 'random-container-0' do
          expect(find('.uploaded-image', visible: false)[:src]).to include ImageUpload.last.url
        end
      end
    end
  end
end
