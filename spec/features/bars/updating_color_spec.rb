feature 'Editing site element', :js do
  scenario 'User can modify the color settings for a bar' do
    color = 'AABBCC'

    OmniAuth.config.add_mock(:google_oauth2, uid: '12345', info: { email: 'bob@lawblog.com' })
    visit users_sign_up_path

    fill_in 'registration_form[site_url]', with: 'mewgle.com'
    check 'registration_form[accept_terms_and_conditions]'
    first('[name=signup_with_google]').click

    expect(page).to have_content 'CHOOSE GOAL'

    first('.goal-block').click

    expect(page).to have_content 'CHOOSE TYPE'

    first('.goal-block').click

    sleep 2
    page.execute_script("$('.introjs-skipbutton').trigger('click')")

    go_to_tab 'Design'

    find('.collapse', text: 'Bar Styling').click
    # TODO: Finish this spec
    # find('.panel-input', text: 'Color').find('input').set color
    #
    # expect(find('.panel-input', text: 'Color').find('input').value.upcase).to eql color

    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
