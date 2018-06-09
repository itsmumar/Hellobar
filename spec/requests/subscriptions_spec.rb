describe 'Subscriptions requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }

  context 'when unauthenticated' do
    before { create :credit_card, user: user }

    describe 'POST :update' do
      it 'responds with a redirect to the login page' do
        put subscription_path

        expect(response).to redirect_to(/sign_in/)
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
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
