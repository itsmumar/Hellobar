require 'integration_helper'

feature "User onboarding statuses get updated as they select a goal for their first Hello Bar", :js do

  given!(:user) { login }

  given(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user, true, UserOnboardingStatus.none)
  end

  before do
    User.any_instance.stub(:onboarding_status_setter).and_return onboarding_status_setter
  end

  after do
    devise_reset
  end

  scenario 'Goal click is tracked' do
    expect(onboarding_status_setter).to receive(:selected_goal!)

    find('.global-sidebar form').click_button('Create New')
    expect(page).to have_content 'SELECT YOUR GOAL'

    within(".goal-block[data-route='money']") do
      click_on 'Select This Goal'
    end
  end
end
