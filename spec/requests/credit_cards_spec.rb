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

    describe 'POST :create' do
      before { stub_cyber_source :store, :purchase }

      let(:credit_card_params) { create :payment_form_params }
      let(:billing_params) { { subscription: 'pro', schedule: 'monthly' } }
      let(:params) do
        {
          site_id: site.id,
          credit_card: credit_card_params,
          billing: billing_params,
          format: :json
        }
      end

      it 'creates credit card' do
        expect {
          post credit_cards_path, params
        }.to change { user.credit_cards.count }.by(1)

        expect(response).to be_successful
      end

      context 'when invalid' do
        let(:credit_card_params) { {} }

        it 'responds with errors' do
          post credit_cards_path, params

          expect(response).not_to be_successful
          expect(json).to match(
            errors:
              [
                'Number can\'t be blank',
                'Expiration can\'t be blank',
                'Month can\'t be blank',
                'Year can\'t be blank',
                'Name can\'t be blank',
                'City can\'t be blank',
                'Zip can\'t be blank',
                'Address can\'t be blank',
                'Country can\'t be blank',
                'Verification value can\'t be blank'
              ]
          )
        end
      end

      context 'for site admin' do
        let(:admin) { create(:site_membership, :admin, site: site).user }

        before do
          login_as admin, scope: :user, run_callbacks: false
        end

        it 'responds with errors' do
          post credit_cards_path, params

          expect(response).not_to be_successful
        end
      end
    end

    describe 'PUT :update' do
      before { stub_cyber_source :update, :purchase }

      let!(:credit_card) { create :credit_card, user: user }
      let!(:new_credit_card) { create :credit_card, user: user }

      let(:billing_params) { { subscription: 'pro', schedule: 'monthly' } }
      let(:params) do
        {
          site_id: site.id,
          billing: billing_params,
          format: :json
        }
      end

      before { ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call }

      it 'links new credit card to subscription' do
        expect { put credit_card_path(new_credit_card, params) }
          .to change { site.current_subscription.credit_card }

        expect(site.current_subscription.credit_card).to eql new_credit_card
        expect(site.current_subscription).to be_a Subscription::Pro
      end

      context 'when subscription type is changed' do
        let!(:previous_subscription) { create :subscription, :free, site: site }

        it 'tracks upgrade event in analytics' do
          expect(Analytics).to receive(:track).with(
            :site, site.id, :change_sub,
            to_subscription: 'Pro', to_schedule: 'monthly',
            from_subscription: 'Free', from_schedule: 'monthly'
          )
          expect(Analytics).to receive(:track).with(:user, user.id, 'Upgraded')

          expect { put credit_card_path(credit_card, params) }
            .to change { site.current_subscription }
        end
      end
    end
  end
end
