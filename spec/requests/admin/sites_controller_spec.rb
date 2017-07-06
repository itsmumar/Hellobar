describe Admin::SitesController do
  let!(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user) }
  let!(:user) { site.owners.first }
  before(:each) { stub_current_admin(admin) }

  context 'PUT admin_user_site_path' do
    let(:update) { put admin_user_site_path(site, user_id: site.owners.first), params }

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

  describe 'POST regenerate_admin_user_site_path' do
    let(:regenerate) { post regenerate_admin_user_site_path(user_id: user, id: site) }

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
end
