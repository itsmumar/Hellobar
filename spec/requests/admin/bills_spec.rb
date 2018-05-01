describe 'Admin::Bills requests' do
  context 'when unauthenticated' do
    describe 'GET :show' do
      it 'responds with a redirect to the login page' do
        get admin_bill_path id: 1

        expect(response).to be_a_redirect
        expect(response.location).to include '/admin/access'
      end
    end
  end

  context 'when authenticated' do
    let!(:admin) { create(:admin) }
    before { stub_current_admin(admin) }

    let!(:bill) { create :bill, :pro, :paid }
    let!(:site) { bill.subscription.site }
    let!(:user) { site.users.first }

    describe 'GET #show' do
      it 'allows admins to see a bill details' do
        get admin_bill_path(bill)
        expect(response).to be_success
      end

      context 'with deleted site' do
        before do
          DestroySite.new(site).call
        end

        it 'responds with success' do
          get admin_bill_path(bill)
          expect(response).to be_success
        end
      end
    end

    describe 'GET #receipt' do
      it 'allows admins to see a bill receipt' do
        get receipt_admin_bill_path(bill)
        expect(response).to be_success
      end

      context 'with deleted site' do
        before do
          DestroySite.new(site).call
        end

        it 'responds with success' do
          get receipt_admin_bill_path(bill)
          expect(response).to be_success
        end
      end
    end

    describe 'PUT #void' do
      it 'voids a bill' do
        put void_admin_bill_path(bill)

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
          put pay_admin_bill_path(bill)

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
          put pay_admin_bill_path(bill)

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
          put refund_admin_bill_path(bill), params
        }.to change(Bill.refunded, :count).by 1

        expect(response).to redirect_to admin_site_path(site)
      end

      context 'when failed' do
        let!(:bill) { create :bill, :pro }

        let(:params) do
          {
            id: bill
          }
        end

        it 'returns refund error' do
          expect {
            put refund_admin_bill_path(bill), params
          }.not_to change(Bill.refunded, :count)
          expect(response).to redirect_to admin_site_path(site)
        end
      end
    end

    describe 'PUT #chargeback' do
      it 'calls ChargebackBill' do
        expect { put chargeback_admin_bill_path(bill) }.to change(Bill.chargedback, :count).by 1
      end

      it 'redirects to site page' do
        put chargeback_admin_bill_path(bill)

        expect(response).to redirect_to admin_site_path(site)
      end
    end
  end
end
