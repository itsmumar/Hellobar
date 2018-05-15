feature 'Editing site element', :js do
  scenario 'User can modify the color settings for a bar' do
    color = 'AABBCC'

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: 'bob@lawblog.com' })
    visit users_sign_up_path

    fill_in 'registration_form[site_url]', with: 'mewgle.com'
    check 'registration_form[accept_terms_and_conditions]'
    first('[name=signup_with_google]').click

    expect(page).to have_content 'SELECT YOUR GOAL'

    first('.goal-block').click_on('Select This Goal')

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
end
