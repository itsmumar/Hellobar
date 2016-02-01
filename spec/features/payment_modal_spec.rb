require 'integration_helper'

feature "Payment modal interaction", js: true do
  before { @user = login }
  after { devise_reset }

  scenario "downgrade to free from pro should say when it's active until" do
    # In the middle of an AB test.  Make sure we use the original
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_return("original")

    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    end_date = site.current_subscription.active_until
    visit edit_site_path(site)
    click_link("Change plan or billing schedule")
    find(".different-plan").click
    basic_plan = find(".package-block.basic", visible: true)
    basic_plan.find(".button").click
    expect(page).to have_content "until #{end_date.strftime("%-m-%-d-%Y")}"
  end

  scenario "upgrade to pro from free" do
    # In the middle of an AB test.  Make sure we use the original
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_return("original")
    allow_any_instance_of(CyberSourceCreditCard::CyberSourceCreditCardValidator).to receive(:validate).and_return(true)
    allow_any_instance_of(PaymentMethod).to receive(:pay).and_return(true)

    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    subscription = create(:free_subscription, site: site, payment_method: payment_method)
    visit edit_site_path(site)
    click_link("Upgrade plan")
    pro_plan = page.find(".package-block.pro")
    pro_plan.find(".button").click

    page.find('.submit').click
    page.find('a', visible: true, text: "OK").click
    expect(page).to have_content "is on the Pro plan"
  end
end
