describe 'Subscriptions requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }

  context 'when unauthenticated' do
    before { create :credit_card, user: user }

    describe 'POST :create' do
      it 'responds with a redirect to the login page' do
        post subscription_path

        expect(response).to redirect_to(/sign_in/)
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
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
          post subscription_path, params
        }.to change { user.credit_cards.count }.by(1)

        expect(response).to be_successful
      end

      context 'when invalid' do
        let(:credit_card_params) { {} }

        it 'responds with errors' do
          post subscription_path, params

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
          post subscription_path, params

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
          credit_card_id: new_credit_card.id,
          billing: billing_params,
          format: :json
        }
      end

      before { ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call }

      it 'links new credit card to subscription' do
        expect { put subscription_path(params) }
          .to change { site.current_subscription.credit_card }

        expect(site.current_subscription.credit_card).to eql new_credit_card
        expect(site.current_subscription).to be_a Subscription::Pro
      end

      context 'when subscription type is changed' do
        let!(:previous_subscription) { create :subscription, :free, site: site }

        it 'changes the subscription' do
          expect { put subscription_path(params) }
            .to change { site.current_subscription }
        end
      end
    end
  end
end
