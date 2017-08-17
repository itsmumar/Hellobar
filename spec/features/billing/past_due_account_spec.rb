require 'integration_helper'

feature 'Billing. Past due account', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, :pro, user: user) }
  given!(:bill) { create(:past_due_bill, subscription: site.current_subscription) }
  given!(:credit_card) { bill.credit_card }

  before do
    login user
  end

  scenario 'displays notification about outstanding bill' do
    visit site_path(site)

    expect(page).to have_content "We could not charge $#{ bill.amount.to_i }.00" \
                                 " on your credit card ending in #{ credit_card.last_digits }." \
                                 ' Update credit card details or Charge again'
  end
end
