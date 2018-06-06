feature 'New credit card modal interaction', :js do
  given(:user) { create :user }
  given(:site) { create :site, :pro, user: user }
  given(:credit_card) { create :payment_form }

  before { stub_cyber_source :store }

  background do
    sign_in user
  end

  scenario 'adding new credit card' do
    visit edit_site_path(site)
    page.find('.show-new-credit-card-modal').click
    add_credit_card
    wait_for_ajax

    expect(page.find('.flash-block.success').text)
      .to eql('Credit card has been successfully created.')
    expect(user.credit_cards.count).to eql(1)
  end

  def add_credit_card
    fill_in 'credit_card[name]', with: credit_card.name
    fill_in 'credit_card[number]', with: credit_card.number
    fill_in 'credit_card[expiration]', with: credit_card.expiration
    fill_in 'credit_card[verification_value]', with: credit_card.verification_value
    fill_in 'credit_card[address]', with: credit_card.address
    fill_in 'credit_card[city]', with: credit_card.city
    fill_in 'credit_card[state]', with: credit_card.state
    fill_in 'credit_card[zip]', with: credit_card.zip
    select 'United States', match: :first, from: 'credit_card[country]'
    page.find('a.submit', text: 'Add').click
  end
end
