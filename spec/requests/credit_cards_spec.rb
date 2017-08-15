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
  end
end
