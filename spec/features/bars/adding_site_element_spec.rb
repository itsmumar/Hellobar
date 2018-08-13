feature 'Adding bars', :js do
  given(:email) { 'bob@lawblog.com' }
  given(:user) { create :user, email: email }

  scenario 'new user can create a site element' do
    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: user.email })

    visit users_sign_up_path

    fill_in 'registration_form[site_url]', with: 'mewgle.com'
    check 'registration_form[accept_terms_and_conditions]'
    first('[name=signup_with_google]').click

    expect(page).to have_content 'Are you sure you want to add the site'

    click_on 'Create Site'

    expect(page).to have_content 'choose your goal'

    first('.goal-block').click

    expect(page).to have_content 'Collect Emails'

    # click_button 'Continue'
    first('.goal-block').click
    sleep 3
    page.execute_script("$('.introjs-skipbutton').trigger('click')")
    find('a', text: 'Save & Publish').click

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

    expect(page).to have_content 'choose your goal'

    first('.goal-block').click

    expect(page).to have_content 'Collect Emails'

    # click_button 'Continue'
    first('.goal-block').click
    sleep 5
    page.execute_script("$('.introjs-skipbutton').trigger('click')")
    find('a', text: 'Save & Publish').click
    expect(page).to have_content('Summary')

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
