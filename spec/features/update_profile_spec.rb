require 'integration_helper'

feature "Update Profile", js: true do
  context "is not an oauth user" do
    before { @user = login }
    after { devise_reset }

    scenario "updates name without updating password" do
      visit profile_path
      fill_in 'First name', with: "ABC 123"
      click_button 'Save & Update'
      expect(page).to have_content('Your settings have been updated.')
    end

    scenario "updates password" do
      visit profile_path
      fill_in 'Current Password', with: @user.password
      fill_in 'New Password', with: "abc123abc"
      fill_in 'Repeat Password', with: "abc123abc"
      click_button 'Save & Update'
      expect(page).to have_content('Your settings have been updated.')
    end

    scenario "putting in invalid data results in error text" do
      visit profile_path
      fill_in 'Current Password', with: @user.password
      fill_in 'New Password', with: "abc123abc"
      fill_in 'Repeat Password', with: "oops"
      click_button 'Save & Update'
      expect(page).to have_content('There was a problem updating your settings')
    end
  end

  context "user is an google oauth user" do
    before do
      @user = create(:authentication).user
      login(@user)
    end
    after { devise_reset }

    scenario "email field is be disabled when loading the page" do
      visit profile_path
      expect(page).to have_css("#user_email[disabled]")
    end

    scenario "email field is enabled after clicking the reveal password button" do
      visit profile_path
      find("#show-password-form").click
      expect(page).to_not have_css("#user_email[disabled]")
    end

    scenario "password fields revealed after clicking the reveal password button" do
      visit profile_path
      expect(find("#user_password", visible: false)).to_not be_visible
      expect(find("#user_password_confirmation", visible: false)).to_not be_visible
      find("#show-password-form").click
      expect(find("#user_password")).to be_visible
      expect(find("#user_password_confirmation")).to be_visible
    end

    scenario "email cannot be changed without setting password" do
      visit profile_path
      find("#show-password-form").click
      fill_in 'Email', with: "mynewemail@email.com"
      click_button 'Save & Update'
      expect(page).to have_content('email cannot be changed without a password')
    end

    scenario "email can be changed by setting password" do
      visit profile_path
      find("#show-password-form").click
      fill_in 'Email', with: "mynewemail@email.com"
      fill_in 'New Password', with: "abc123abc"
      fill_in 'Repeat Password', with: "abc123abc"
      click_button 'Save & Update'
      expect(page).to have_content('Your settings have been updated.')
    end
  end
end
