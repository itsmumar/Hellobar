describe 'Affiliate require credit card' do
  let(:user) { create(:user, :affiliate) }
  let(:require_credit_card) { false }

  before do
    stub_cyber_source(:store)

    create(:partner, affiliate_identifier: user.affiliate_identifier,
                     require_credit_card: require_credit_card,
                     partner_plan_id: 'growth_60')

    sign_in user
  end

  context 'when affiliate partner does not require credit card' do
    let(:require_credit_card) { false }

    it 'redirects to new site page' do
      visit root_path
      expect(page).to have_content 'Create A New Site'
    end
  end

  context 'when affiliate partner requires credit card' do
    let(:require_credit_card) { true }

    it 'redirect to credit card page' do
      visit root_path
      expect(page).to have_content 'Billing Information'
      expect(page).to have_content('You’re signing up for a free 60 day trial of our Growth Plan')
    end

    context 'when user enters credit card' do
      let(:credit_card_attributes) { build(:payment_form_params) }

      it 'redirects to new site page' do
        visit root_path

        fill_in 'credit_card[name]', with: credit_card_attributes[:name]
        fill_in 'credit_card[number]', with: credit_card_attributes[:number]
        fill_in 'credit_card[expiration]', with: credit_card_attributes[:expiration]
        fill_in 'credit_card[verification_value]', with: credit_card_attributes[:verification_value]
        fill_in 'credit_card[address]', with: credit_card_attributes[:address]
        fill_in 'credit_card[city]', with: credit_card_attributes[:city]
        fill_in 'credit_card[state]', with: credit_card_attributes[:state]
        fill_in 'credit_card[zip]', with: credit_card_attributes[:zip]
        select 'Belarus', from: 'credit_card[country]'

        find('input[type="submit"]').click

        expect(page).to have_content 'Create A New Site'
      end
    end
  end
end
