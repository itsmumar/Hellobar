describe 'Admin Bills requests' do
  context 'when unauthenticated' do
    describe 'GET :show' do
      it 'responds with a redirect to the login page' do
        get admin_user_bill_path user_id: 1, id: 1

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
    let!(:bill) { create :pro_bill, :paid }

    describe 'GET #show' do
      it 'allows admins to see a bill' do
        get admin_user_bill_path(user_id: user.id, id: bill)
        expect(response).to be_success
      end
    end

    describe 'PUT #void' do
      it 'voids a bill' do
        put admin_user_bill_void_path(user_id: user, bill_id: bill)

        expect(response).to redirect_to admin_user_path(user)
        expect(bill.reload).to be_voided
      end
    end

    describe 'PUT #refund' do
      before { stub_cyber_source :refund }

      it 'refunds a bill' do
        expect {
          put admin_user_bill_refund_path(user_id: user, bill_id: bill, bill_recurring: { amount: 10 })
        }.to change(Bill::Refund, :count).by 1

        expect(response).to redirect_to admin_user_path(user)
      end
    end
  end
end
