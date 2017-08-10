require 'integration_helper'

feature 'Billing. Past due account', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, :pro, user: user) }
  given!(:bill) { create(:past_due_bill, subscription: site.current_subscription) }
  given!(:card) { bill.payment_method_detail }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true

    login user
  end

  scenario 'displays notification about outstanding bill' do
    visit site_path(site)

    expect(page).to have_content "We could not charge $#{ bill.amount.to_i }.00" \
                                 " on your credit card ending in #{ card.last_digits }." \
                                 ' Update credit card or Try again'
  end
end
