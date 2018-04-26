require 'integration_helper'

feature 'Adding and editing bars', :js do
  given(:select_goal_label) { 'Select This Goal' }
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }

  before do
    allow_any_instance_of(SiteElementSerializer)
      .to receive(:proxied_url2png).and_return('')
    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation).and_return('original')
  end

  scenario 'new user can create a site element' do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })

    visit users_sign_up_path

    fill_in 'registration_form[site_url]', with: 'mewgle.com'
    check 'registration_form[accept_terms_and_conditions]'
    first('[name=signup_with_google]').click

    expect(page).to have_content 'Are you sure you want to add the site'

    click_on 'Create Site'

    expect(page).to have_content 'SELECT YOUR GOAL'

    first('.goal-block').click_on(select_goal_label)

    expect(page).to have_content 'PROMOTE A SALE'

    click_button 'Continue'
    click_button 'Save & Publish'

    expect(page).to have_content('Summary')

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  scenario 'existing user can create a site element' do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345')
    site = create(:site, :with_rule, :with_user)
    user = site.owners.last
    user.authentications.create(provider: 'google_oauth2', uid: '12345')

    visit new_user_session_path
    fill_in 'Your Email', with: user.email

    click_button 'Continue'

    expect(page).to have_content 'SELECT YOUR GOAL'

    first('.goal-block').click_on(select_goal_label)

    expect(page).to have_content 'PROMOTE A SALE'

    click_button 'Continue'
    click_button 'Save & Publish'

    expect(page).to have_content('Summary')

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  context 'Collect Email goal' do
    let(:user) { create :user }
    let(:site) { create :site, :with_rule, user: user }

    before do
      allow_any_instance_of(ApplicationController)
        .to receive(:ab_variation).and_return('variant')

      create :contact_list, site: site

      sign_in user

      visit new_site_site_element_path(site)

      find('.goal-block.contacts').click_on(select_goal_label)
      click_button 'Continue'

      click_on 'Goals'

      @phone_field = find('.item-block[data-field-type="builtin-phone"]')
      @phone_field.find('.hellobar-icon-check-mark').click if @phone_field[:class].include?('is-selected')

      @name_field = find('.item-block[data-field-type="builtin-name"]')
      @name_field.find('.hellobar-icon-check-mark').click if @name_field[:class].include?('is-selected')
    end

    scenario 'only built-in-email enabled' do
      click_button 'Save & Publish'
      expect(page).to have_content('Summary')
      se = SiteElement.last
      se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
      expect(se_settings['builtin-phone']).to eq(false)
    end

    scenario 'built-in-phone enabled' do
      @phone_field.hover
      @phone_field.find('.hellobar-icon-check-mark').click
      click_button 'Save & Publish'
      expect(page).to have_content('Summary')
      se = SiteElement.last
      se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
      expect(se_settings['builtin-phone']).to eq(true)
    end

    scenario 'built-in-name enabled' do
      @name_field.hover
      @name_field.find('.hellobar-icon-check-mark').click
      click_button 'Save & Publish'
      expect(page).to have_content('Summary')
      se = SiteElement.last
      se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
      expect(se_settings['builtin-name']).to eq(true)
    end

    scenario 'only multiple built-in fields enabled' do
      @name_field.hover
      @name_field.find('.hellobar-icon-check-mark').click
      @phone_field.hover
      @phone_field.find('.hellobar-icon-check-mark').click
      click_button 'Save & Publish'
      expect(page).to have_content('Summary')
      se = SiteElement.last
      se_settings = se.settings['fields_to_collect'].map { |a| [a['type'], a['is_enabled']] }.to_h
      expect(se_settings['builtin-phone']).to eq(true)
      expect(se_settings['builtin-name']).to eq(true)
      expect(se_settings['builtin-email']).to eq(true)
    end

    scenario 'custom field' do
      click_link 'Style'
      find('a.change-selection').click
      find('h6', text: 'Modal').click
      find('.step-settings').click

      find('div.item-block.add', text: 'Add field').click

      expect(page).to have_selector '.new-item-prototype > input'
      find('.new-item-prototype > input').set "Age\n"

      click_button 'Save & Publish'
      expect(page).to have_content('Summary')

      find('a', text: 'Manage').click
      find('.dropdown-wrapper.adjusted').hover
      find('.dropdown-wrapper.adjusted').find('a', text: 'Edit').click

      expect(page).to have_content('Age')
      expect(page).to have_css('.item-block[data-field-type="text"] .hellobar-icon-check-mark')
      expect(page).to have_content('Add field')
    end
  end

  scenario 'User can set phone number for click to call' do
    user = create(:user)
    site = create(:site, :with_rule, user: user)
    phone_number = '+12025550144'

    sign_in user

    visit new_site_site_element_path(site)

    find('.goal-block.call').click_on(select_goal_label)

    all('input')[0].set('Hello from Hello Bar')
    all('input')[1].set('Button McButtonson')
    all('input')[2].set(phone_number)

    click_button 'Continue'

    click_on 'Save & Publish'

    expect(page).to have_content('Get Free Growth') # waits for next page load
    element = SiteElement.last

    expect(element.phone_number).to eql(phone_number)
  end

  scenario 'User can modify the color settings for a bar' do
    color = 'AABBCC'

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: 'bob@lawblog.com' })
    visit users_sign_up_path

    fill_in 'registration_form[site_url]', with: 'mewgle.com'
    check 'registration_form[accept_terms_and_conditions]'
    first('[name=signup_with_google]').click

    expect(page).to have_content 'SELECT YOUR GOAL'

    first('.goal-block').click_on(select_goal_label)

    expect(page).to have_content 'PROMOTE A SALE'

    click_button 'Continue'

    expect(page).to have_content 'STYLE'

    click_link 'Next'

    within('.step-wrapper') do
      first('.color-select-block input').set color

      # make sure the color is set there by clicking to show the dropdown
      # and then hide it
      2.times { first('.color-select-wrapper').click }
    end

    click_link 'Next'

    expect(page).to have_content 'TARGETING'

    click_on 'Content'

    expect(page).to have_content('Background Color')

    expect(first('.color-select-block input').value.upcase).to eql color

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

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
