require 'integration_helper'

feature "Trial User", js: true do
  before do
    @user = login
    @site = create(:site)
    @site.users << @user
    subscription = Subscription::Pro.new(schedule: "monthly")
    @site.change_subscription(subscription, nil, 90.day) # 90 day subscription
  end
  after { devise_reset }

  scenario "shows a button in the header that prompts user to enter payment" do
    visit site_path(@site)
    expect(page).to have_content('ENJOYING HELLO BAR PRO? CLICK HERE TO KEEP IT.')
  end

  scenario "allows users to downgrade" do
    allow_any_instance_of(Subscription).to receive(:problem_with_payment?).and_return(true)
    allow_any_instance_of(Site).to receive(:has_script_installed?).and_return(true)
    visit site_path(@site)
    expect(page).to have_content('Your subscription has not been renewed')
    find(".show-downgrade-modal").click
    click_link("Downgrade")
    expect(@site.reload.current_subscription).to be_a(Subscription::Free)
  end
end
