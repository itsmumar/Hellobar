describe 'PaymentMethods requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }

  context 'when unauthenticated' do
    before { create :payment_method, user: user }

    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get payment_methods_path

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      before { create :payment_method, user: user }

      it 'responds with success' do
        get payment_methods_path(format: :json)
        expect(response).to be_successful
      end
    end

    describe 'POST :create' do
      before { stub_cyber_source :store, :purchase }

      let(:payment_method_details) { create :payment_form_params }
      let(:billing_params) { { subscription: 'pro', schedule: 'monthly' } }
      let(:params) do
        {
          site_id: site.id,
          payment_method_details: payment_method_details,
          billing: billing_params,
          format: :json
        }
      end

      it 'creates payment method' do
        expect {
          post payment_methods_path, params
        }.to change { user.payment_methods.count }.by(1)

        expect(response).to be_successful
      end

      context 'when invalid' do
        let(:payment_method_details) { {} }

        it 'responds with errors' do
          post payment_methods_path, params

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
          post payment_methods_path, params

          expect(response).not_to be_successful
        end
      end
    end

    describe 'PUT :update' do
      before { stub_cyber_source :update, :purchase }

      let!(:payment_method) { create :payment_method, user: user }

      let(:payment_method_details) { create :payment_form_params }
      let(:billing_params) { { subscription: 'pro', schedule: 'monthly' } }
      let(:params) do
        {
          site_id: site.id,
          payment_method_details: payment_method_details,
          billing: billing_params,
          format: :json
        }
      end

      it 'creates new credit card' do
        expect { put payment_method_path(payment_method, params) }
          .to change { user.payment_method_details.count }.by(1)

        expect(response).to be_successful
      end

      it 'changes subscription to Pro' do
        expect { put payment_method_path(payment_method, params) }
          .to change { site.current_subscription }

        expect(site.current_subscription).to be_a Subscription::Pro
      end

      context 'without payment_method_details' do
        let(:payment_method_details) { {} }

        it 'does not create new credit card' do
          expect { put payment_method_path(payment_method, params) }
            .not_to change { user.payment_method_details.count }

          expect(response).to be_successful
        end

        it 'changes subscription to Pro' do
          expect { put payment_method_path(payment_method, params) }
            .to change { site.current_subscription }

          expect(site.current_subscription).to be_a Subscription::Pro
        end
      end

      context 'when upgrading' do
        let!(:previous_subscription) { create :subscription, :free, site: site }

        it 'tracks upgrade event in analytics' do
          expect(Analytics).to receive(:track).with(
            :site, site.id, :change_sub,
            to_plan: 'Pro', to_schedule: 'monthly',
            from_plan: 'Free', from_schedule: 'monthly'
          )
          expect(Analytics).to receive(:track).with(:user, user.id, 'Upgraded')

          expect { put payment_method_path(payment_method, params) }
            .to change { site.current_subscription }
        end
      end
    end
  end
end
