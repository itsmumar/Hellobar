require 'integration_helper'

feature "Payment modal interaction", js: true do
  before do
    @user = login
  end

  scenario "downgrade to free from pro should say when it's active until" do
    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    end_date = site.current_subscription.active_until
    visit edit_site_path(site)
    click_link("Change plan or billing schedule")
    find(".different-plan").click
    basic_plan = find(".package-block.basic")
    basic_plan.find(".button").click
    expect(page).to have_content "until #{end_date.strftime("%-m-%-d-%Y")}"
  end

  scenario "upgrade to pro from free" do
    allow_any_instance_of(CyberSourceCreditCard::CyberSourceCreditCardValidator).to receive(:validate).and_return(true)
    allow_any_instance_of(PaymentMethod).to receive(:pay).and_return(true)

    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    subscription = create(:free_subscription, site: site, payment_method: payment_method)
    visit edit_site_path(site)
    page.find('footer .show-upgrade-modal').click
    pro_plan = page.find(".package-block.pro")
    pro_plan.find(".button").click

    page.find('.submit').click
    page.find('a', text: "OK").click
    expect(page).to have_content "is on the Pro plan"
  end
end
