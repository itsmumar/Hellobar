require 'integration_helper'

feature 'User can create a site element', js: true do
  after { devise_reset }
  before do
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
  end

  scenario 'new user can create a site element' do
    OmniAuth.config.add_mock(:google_oauth2, {uid: '12345', info: {email: 'bob@lawblog.com'}})
    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'sign-up-button'

    first(:button, 'Select This Goal').click
    first(:button, 'Continue').click
    first(:button, 'Save & Publish').click

    expect(page).to have_content('Summary', visible: true)

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'existing user can create a site element' do
    OmniAuth.config.add_mock(:google_oauth2, {:uid => '12345'})
    user = create(:user)
    site = user.sites.create(url: random_uniq_url)
    create(:rule, site: site)
    auth = user.authentications.create({
      provider: 'google_oauth2',
      uid: '12345'
    })

    visit new_user_session_path

    fill_in 'Your Email', with: user.email
    click_button 'Continue'

    first(:button, 'Select This Goal').click
    first(:button, 'Continue').click
    first(:button, 'Save & Publish').click

    expect(page).to have_content('Summary', visible: true)
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario "A user can create a site element without seeing an interstitial" do
    user = login(create(:site_membership, :with_site_rule).user)
    {
      emails:       "Collect Email",
      click:        "Click Link",
      call:         "Talk to Visitors",
      social:       "Social",
      announcement: "Announcement"
    }.each do |anchor, header|
      visit new_site_site_element_path(user.sites.first,
                                       anchor: "/settings/#{anchor}",
                                       skip_interstitial: true)
      expect(page).to have_content(header, visible: true)
    end
  end
end

feature 'User can set a phone number for click to call', js: true do
  before do
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
  end

  after { devise_reset }

  scenario 'the site sets a custom country so they can use 1800' do
    membership = create(:site_membership, :with_site_rule)
    user = membership.user
    login(user)

    find(:button, 'Create New').click
    find('button[value=call]').click
    all('input')[0].set('Hello from Hello Bar')
    all('input')[1].set('Button McButtonson')
    all('input')[2].set('18001231234')
    find('select').select('Custom')
    find('button', text: 'Continue').click
    find('button', text: 'Save & Publish').click

    expect(page).to have_css('html') # waits for next page load
    element = SiteElement.last

    expect(element.phone_number).to eql('18001231234')
  end
end

feature 'User can toggle colors for a site element', js: true do
  before do
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
    allow_any_instance_of(ApplicationController).
      to receive(:get_ab_variation).and_return('original')
  end

  after { devise_reset }

  scenario 'user can modify the color settings for a bar' do
    OmniAuth.config.add_mock(:google_oauth2, {uid: '12345', info: {email: 'bob@lawblog.com'}})
    visit root_path

    fill_in 'site[url]', with: 'mewgle.com'
    click_button 'sign-up-button'

    first(:button, 'Select This Goal').click
    first(:button, 'Continue').click
    page.find('a', text: 'Next').click
    page.find('a', text: /colors/i).click

    page.first('.color-select-block input').set('AABBCC')
    page.find('a', text: 'Prev').click
    page.find('a', text: 'Next').click

    expect(page).to have_content('Background Color', visible: true)
    val = page.first('.color-select-block input').value
    expect(val).to eql('AABBCC')
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

feature 'User can edit a site element', js: true do
  before do
    @user = login
    allow_any_instance_of(SiteElementSerializer).
      to receive(:proxied_url2png).and_return('')
  end

  after { devise_reset }

  scenario 'user can edit a site element' do
    site = @user.sites.first
    site.rules << create(:rule)
    create(:site_element, rule: site.rules.first)
    site.reload

    visit edit_site_site_element_path(site, site.site_elements.last)
    page.find('a', text: 'Next').click
    page.find('a', text: 'Next').click
    page.find('a', text: /text/i).click

    first('.ember-text-field').set('Dear I fear were facing a problem')
    page.find('button', text: 'Save & Publish').click
    expect(page).to have_content('Dear I fear were facing a problem', visible: true)
  end
end
