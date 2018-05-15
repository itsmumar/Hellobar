feature 'Editing site element', :js do
  scenario 'User can edit a site element' do
    user = create :user, :with_site

    site = user.sites.first
    site.rules << create(:rule)

    create :site_element, rule: site.rules.first

    site.reload

    sign_in user

    visit edit_site_site_element_path(site, site.site_elements.last)

    bypass_setup_steps(2)

    within('.step-wrapper') do
      click_on 'Text'
      find('.questions .toggle-off').click

      expect(page).to have_content 'QUESTION'
    end

    value = 'Dear I fear because were facing a problem'
    first('.ember-text-field').set(value)

    click_on 'Save & Publish'

    expect(page).to have_content(value)
  end
end
