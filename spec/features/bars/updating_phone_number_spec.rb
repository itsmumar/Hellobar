feature 'Adding and editing bars', :js do
  # TODO: Add further testing here!
  
  scenario 'User can set phone number for click to call' do
    user = create(:user)
    site = create(:site, :with_rule, user: user)
    phone_number = '+12025550144'

    sign_in user

    visit new_site_site_element_path(site)

    find('.goal-block.call').click

    # all('input')[0].set('Hello from Hello Bar')
    # all('input')[1].set('Button McButtonson')
    # all('input')[2].set(phone_number)
    #
    # click_button 'Continue'
    #
    # find('a', text: 'Save & Publish').click

    expect(page).to have_content('Get Phone Calls') # waits for next page load
    # element = SiteElement.last

    # expect(element.phone_number).to eql(phone_number)
  end
end
