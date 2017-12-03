describe 'Admin::Sites requests' do
  let!(:admin) { create(:admin) }
  let(:site) { create(:site, :free_subscription, :with_user) }
  let!(:user) { site.owners.first }
  before(:each) { stub_current_admin(admin) }

  context 'GET admin_site_path' do
    before do
      get admin_site_path(site)
    end

    it 'responds with success' do
      expect(response).to be_success
    end

    it 'shows the specified site' do
      within('.site-title') do
        expect(page).to have_content(site.url)
      end
    end

    it 'shows the billing history' do
      within('.site_section.billing_history') do
        expect(page).to have_content('Billing History')
        expect(page).to have_selector('table tr', count: 1)
      end
    end

    it 'shows the subscription history' do
      within('.site_section.subscription_history') do
        expect(page).to have_content('Subscription History')
        expect(page).to have_selector('table tr', count: 1)
      end
    end

    context 'when site is shared' do
      before do
        create(:site_membership, site: site)
      end

      it 'shows all site users' do
        within('.site_section.site_users') do
          expect(page).to have_content('Shared By')
          expect(page).to have_selector('table tr', count: 2)
        end
      end
    end
  end

  context 'PUT admin_site_path' do
    let(:update) { put admin_site_path(site), params }

    context 'when updating subscription' do
      let(:params) { { subscription: { subscription: 'ProComped', schedule: 'monthly' } } }

      it 'changes the subscription' do
        expect { update }.to change { site.reload.current_subscription }
        expect(site.current_subscription).to be_a Subscription::ProComped
        expect(site.current_subscription.schedule).to eql 'monthly'
      end

      context 'when trying to upgrade and it must be paid' do
        let(:params) { { subscription: { subscription: 'Enterprise', schedule: 'monthly' } } }

        it 'raises error' do
          update
          expect(flash[:error]).to eql 'You are trying to upgrade subscription but it must be paid by the user'
        end
      end

      context 'when difference between subscription is less than 0' do
        let(:site) { create(:site, :with_user, :pro, schedule: :yearly) }
        let(:params) { { subscription: { subscription: 'Enterprise', schedule: 'monthly' } } }

        before { create(:recurring_bill, :paid, subscription: site.current_subscription) }

        it 'raises error' do
          update
          expect(flash[:error]).to eql 'You are trying to downgrade subscription but difference between subscriptions is -49.0$. Try to refund this amount first'
        end
      end

      context 'when trying to downgrade' do
        let(:site) { create(:site, :with_user, :pro) }
        let(:params) { { subscription: { subscription: 'Free', schedule: 'monthly' } } }

        it 'downgrades successfully' do
          update
          expect(site.reload.current_subscription).to be_a Subscription::Free
        end
      end

      context 'when trying to upgrade from Free subscription' do
        let(:site) { create(:site, :with_user, :free_subscription) }

        %w[ProManaged ProComped FreePlus].each do |to_subscription|
          context "to #{ to_subscription }" do
            let(:params) { { subscription: { subscription: to_subscription, schedule: 'monthly' } } }

            it 'upgrades successfully' do
              update
              expect(site.reload.current_subscription).to be_a Subscription.const_get(to_subscription)
            end
          end
        end
      end
    end

    context 'when adding trial subscription', :freeze do
      let(:params) { { subscription: { subscription: 'Pro', trial_period: '10' } } }

      it 'changes the subscription with trial_end_date' do
        expect { update }.to change { site.reload.current_subscription }
        expect(site.current_subscription).to be_a Subscription::Pro
        expect(site.current_subscription.trial_end_date).to eql 10.days.from_now
      end

      context 'but site already on Pro' do
        let(:params) { { subscription: { subscription: 'Pro', trial_period: '10' } } }

        before { AddTrialSubscription.new(site, params[:subscription]).call }

        it 'changes the subscription with trial_end_date' do
          expect(site.current_subscription).to be_a Subscription::Pro
          expect { update }.not_to change { site.reload.current_subscription }
          expect(site.current_subscription.trial_end_date).to eql 20.days.from_now
        end
      end
    end

    context 'when updating invoice_information' do
      let(:params) { { site: { invoice_information: '12345 Main St' } } }

      it 'updates information' do
        expect { update }.to change { site.reload.invoice_information }.to(params[:site][:invoice_information])
      end
    end

    context 'when any error occurs' do
      before { allow_any_instance_of(CalculateBill).to receive(:call).and_raise(StandardError, 'some error') }
      let(:params) { { subscription: { subscription: 'ProComped', schedule: 'monthly' } } }

      specify { expect { update }.to raise_error 'some error' }

      context 'when not in test env' do
        before { allow(Rails.env).to receive(:test?).and_return false }

        it 'displays error' do
          update
          expect(flash[:error]).to eql 'There was an error trying to update the subscription: some error'
        end
      end
    end
  end

  describe 'POST regenerate_admin_site_path' do
    let(:regenerate) { post regenerate_admin_site_path(id: site) }

    before { allow(StaticScriptAssets).to receive(:render).and_return '$INJECT_DATA;$INJECT_MODULES' }

    context 'when the site exists' do
      it 'generates the script for the site' do
        regenerate
        expect(response).to be_success
      end

      it 'returns success message' do
        regenerate
        expect(json).to match message: 'Site regenerated'
      end

      context 'when regenerating script fails' do
        before { expect(RenderStaticScript).to receive_service_call.and_raise RuntimeError }

        it 'returns error message' do
          regenerate
          expect(response.status).to eq(500)
          expect(json).to match message: "Site's script failed to generate"
        end
      end
    end

    context 'when the site does not exist' do
      let(:user) { create :user }
      let(:site) { Site.new id: -1 }

      it 'returns error message' do
        regenerate
        expect(response.status).to eq(404)
        expect(json).to match message: 'Site was not found'
      end
    end
  end

  describe 'PUT add_free_days', :freeze do
    let(:params) { { free_days: { count: '10' } } }
    let(:current_subscription) { site.current_subscription }
    let(:next_bill) { current_subscription.bills.last }
    let(:current_bill) { current_subscription.bills.first }

    let(:add_free_days) do
      put add_free_days_admin_site_path(site), params
    end

    context 'with a paid subscription' do
      before do
        stub_cyber_source :purchase
        ChangeSubscription.new(site, { subscription: 'Pro' }, create(:credit_card)).call
      end

      it 'pushes next billing date forward' do
        expect { add_free_days }
          .to change { next_bill.reload.start_date }
          .by(10.days) \

          .and change { next_bill.reload.end_date }
          .by(10.days) \

          .and change { next_bill.reload.bill_at }
          .by(10.days) \

          .and change { current_bill.reload.end_date }
          .by(10.days)
      end
    end

    context 'with a trail subscription' do
      before do
        stub_cyber_source :purchase
        AddTrialSubscription.new(site, subscription: 'Pro', trial_period: '10').call
      end

      it 'adds free days to the trial' do
        expect { add_free_days }
          .to change { current_bill.reload.end_date }
          .by(10.days) \

          .and change { current_subscription.reload.trial_end_date }
          .by(10.days)
      end
    end

    context 'when days number less than 1' do
      let(:params) { { free_days: { count: '0' } } }

      it 'sets flash message' do
        add_free_days
        expect(flash[:error]).to eql 'Invalid number of days'
        expect(response).to redirect_to admin_site_path(site.id)
      end
    end

    context 'when subscription is free' do
      it 'sets flash message' do
        add_free_days
        expect(flash[:error]).to eql 'Could not add trial days to a free subscription'
        expect(response).to redirect_to admin_site_path(site.id)
      end
    end
  end
end
