require 'integration_helper'

feature 'User onboarding statuses get updated as they select a goal for their first Hello Bar', :js do
  given!(:user) { create(:user) }
  given!(:site) { create(:site, :with_rule, user: user) }

  given(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user, true, UserOnboardingStatus.none)
  end

  before do
    sign_in user
    allow_any_instance_of(GenerateStaticScriptModules).to receive(:call)
    allow_any_instance_of(User).to receive(:onboarding_status_setter).and_return onboarding_status_setter
  end

  scenario 'Goal click is tracked' do
    expect(onboarding_status_setter).to receive(:selected_goal!)

    find('.global-sidebar form').click_button('Create New')
    expect(page).to have_content 'SELECT YOUR GOAL'

    within('.goal-block.money') do
      click_on 'Select This Goal'
    end
  end
end
