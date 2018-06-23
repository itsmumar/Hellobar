describe 'CreditCards requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }

  context 'when unauthenticated' do
    before { create :credit_card, user: user }

    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get credit_cards_path

        expect(response).to redirect_to(/sign_in/)
      end
    end

    describe 'GET :new' do
      it 'responds with a redirect to the login page' do
        get new_credit_card_path

        expect(response).to redirect_to(/sign_in/)
      end
    end

    describe 'POST :create' do
      it 'responds with a redirect to the login page' do
        post credit_cards_path

        expect(response).to redirect_to(/sign_in/)
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      before { create :credit_card, user: user }

      it 'responds with success' do
        get credit_cards_path(format: :json)
        expect(response).to be_successful
      end
    end

    describe 'GET :new' do
      context 'when sign_up from affiliate link' do
        let(:user) { create :user, :affiliate, site: site }

        before do
          create(:partner, affiliate_identifier: user.affiliate_identifier)
        end

        it 'responds with success' do
          get new_credit_card_path
          expect(response).to be_successful
        end
      end

      context 'when sign_up not from affiliate link' do
        it 'redirects to new_site_site_element_path' do
          get new_credit_card_path
          expect(response).to redirect_to(new_site_site_element_path(site))
        end
      end
    end

    describe 'POST :create' do
      let(:credit_card_attributes) { build(:payment_form_params) }

      before do
        stub_cyber_source(:store)
      end

      it 'create a new credit card' do
        expect {
          post credit_cards_path, credit_card: credit_card_attributes
        }.to change { user.credit_cards.reload.count }.by(1)
      end

      it 'redirects to new_site_site_element_path' do
        post credit_cards_path, credit_card: credit_card_attributes
        expect(response).to redirect_to(new_site_site_element_path(site))
      end
    end
  end
end
