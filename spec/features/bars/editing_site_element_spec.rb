feature 'Editing site element', :js do
  scenario 'User can edit a site element' do
    site = create :site, :with_user, :pro
    user = site.owners.last

    site.rules << create(:rule)

    create :site_element, :email, rule: site.rules.first

    site.reload

    sign_in user

    visit edit_site_site_element_path(site, site.site_elements.last)

    find('h6', text: 'Collect emails').click
    go_to_tab 'Design'
    find('.collapse', text: 'Leading Question').click
    find('.questions .toggle-switch').click

    expect(page).to have_content 'Question'

    value = 'Dear I fear because were facing a problem'
    first('.ember-text-field').set(value)

    find('a', text: 'Save & Publish').click

    expect(page).to have_content(value)
  end
end
