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
  end
end
