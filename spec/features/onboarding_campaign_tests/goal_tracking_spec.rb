require 'integration_helper'

feature "User onboarding statuses get updated as they select a goal for their first Hello Bar" do

  before do
    # initialize the environment in the necessary order before testing
    user
    goals
  end
  after { devise_reset }

  let(:user) {login}
  let(:goals) do
    page.find(".global-sidebar form .button").click
    page.all(".goal-block").collect{|block|block['data-route']}
  end
  let(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user, true, UserOnboardingStatus.none)
  end

  scenario "Each goal click is tracked", js: true, dd: true do
    User.any_instance.stub(:onboarding_status_setter) {onboarding_status_setter}

    expect(goals.size > 1).to be_true
    expect(onboarding_status_setter).to receive(:selected_goal!).exactly(goals.size).times
    click_through_all_goal_interstitial_options
  end

  def click_through_all_goal_interstitial_options
    goals.each do |goal|
      within (".goal-block[data-route='#{goal}']") do
        button = first(".button")
         unless button
          # give the UI some time to finish loading controls.
          sleep 1
          button = first(".button")
        end

        builder = page.driver.browser.action
        builder.key_down(:control)
        builder.click(button.native)

        builder.key_up(:control)

        builder.perform
      end
    end
  end
end
