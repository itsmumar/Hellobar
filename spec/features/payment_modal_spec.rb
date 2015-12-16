require 'integration_helper'

feature "Payment modal interaction", js: true do
  before { @user = login }
  after { devise_reset }

  scenario "downgrade to free from pro" do
    site = @user.sites.first
    site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
    visit edit_site_path(site)
    click_link("Upgrade plan")
    basic_plan = find(".package-block.basic")
    basic_plan.find(".button").click
    click_link("Downgrade")

    expect(site.reload.current_subscription).to be_a(Subscription::Free)
  end

end
