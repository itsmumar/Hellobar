describe 'Admin::Bills requests' do
  context 'when unauthenticated' do
    describe 'GET :show' do
      it 'responds with a redirect to the login page' do
        get admin_site_bill_path site_id: 1, id: 1

        expect(response).to be_a_redirect
        expect(response.location).to include '/admin/access'
      end
    end
  end

  context 'when authenticated' do
    let!(:admin) { create(:admin) }
    before { stub_current_admin(admin) }

    let!(:user) { create :user }
    let!(:site) { create :site, user: user }
    let!(:bill) { create :bill, :pro, :paid }

    describe 'GET #show' do
      it 'allows admins to see a bill' do
        get admin_site_bill_path(site_id: site.id, id: bill)
        expect(response).to be_success
      end

      context 'with deleted site' do
        before do
          DestroySite.new(site).call
        end

        it 'responds with a redirect to the login page' do
          get admin_site_bill_path(site_id: site.id, id: bill)
          expect(response).to be_success
        end
      end
    end

    describe 'PUT #void' do
      it 'voids a bill' do
        put void_admin_site_bill_path(site_id: site, id: bill)

        expect(response).to redirect_to admin_site_path(site)
        expect(bill.reload).to be_voided
      end
    end

    describe 'PUT #pay' do
      let(:bill) { create :bill, :pro }

      context 'when charge is successful' do
        before do
          stub_cyber_source :purchase
        end

        it 'pays a bill' do
          put pay_admin_site_bill_path(site_id: site, id: bill)

          expect(request.flash[:success]).to be_present
          expect(response).to redirect_to admin_site_path(site)
          expect(bill.reload).to be_paid
        end
      end

      context 'when charge is unsuccessful' do
        before do
          stub_cyber_source :purchase, success?: false
        end

        it 'does not pay the bill' do
          put pay_admin_site_bill_path(site_id: site, id: bill)

          expect(request.flash[:error]).to be_present
          expect(response).to redirect_to admin_site_path(site)
          expect(bill.reload).to be_failed
        end
      end
    end

    describe 'PUT #refund' do
      before { stub_cyber_source :refund }
      let(:params) do
        {
          bill_recurring: { amount: 10 }
        }
      end

      it 'refunds a bill' do
        expect {
          put refund_admin_site_bill_path(site_id: site, id: bill), params
        }.to change(Bill::Refund, :count).by 1

        expect(response).to redirect_to admin_site_path(site)
      end

      context 'when failed' do
        let(:params) do
          {
            id: bill,
            bill_recurring: { amount: -100 }
          }
        end

        it 'returns refund error' do
          expect {
            put refund_admin_site_bill_path(site_id: site, id: bill), params
          }.not_to change(Bill::Refund, :count)
          expect(response).to redirect_to admin_site_path(site)
        end
      end
    end
  end
end
