describe 'Bills requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let!(:bill) { create :bill, site: site }

  context 'when unauthenticated' do
    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get bill_path(bill)

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :show' do
      it 'responds with success' do
        get bill_path(bill)
        expect(response).to be_successful
      end

      context 'when bill is failed' do
        let!(:bill) { create :bill, :problem, site: site }

        it 'responds with :not_found' do
          expect { get bill_path(bill) }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when no permissions' do
        before { allow(Permissions).to receive(:view_bills?).and_return false }

        it 'responds with :not_found' do
          expect { get bill_path(bill) }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    describe 'PUT :pay' do
      before { stub_cyber_source :purchase }

      it 'pays bill' do
        put pay_bill_path(bill)
        expect(response).to redirect_to site_path(site)
        expect(flash[:success]).to eql 'Your bill has been successfully paid. Thank you!'
        expect(bill.reload).to be_paid
      end

      context 'when bill with problem' do
        let!(:bill) { create :bill, :problem, site: site }

        it 'responds with success' do
          put pay_bill_path(bill)
          expect(response).to redirect_to site_path(site)
          expect(bill.reload).to be_paid
        end
      end

      context 'when cannot pay bill' do
        let!(:bill) { create :bill, :problem, site: site }
        let(:card) { bill.payment_method_detail }

        before { stub_cyber_source :purchase, success?: false }

        it 'responds with success' do
          put pay_bill_path(bill)

          expect(response)
            .to redirect_to edit_site_path(site, should_update_card: true, anchor: 'problem-bill')
          expect(flash[:alert])
            .to eql "There was a problem while charging your credit card ending in #{ card.last_digits }." \
                    ' You can fix this by adding another credit card'

          expect(bill.reload).not_to be_paid
        end
      end

      context 'when no permissions' do
        before { allow(Permissions).to receive(:view_bills?).and_return false }

        it 'responds with :not_found' do
          expect { put pay_bill_path(bill) }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
