describe 'Admin::Admins requests' do
  let!(:admin) { create(:admin) }

  before { stub_current_admin(admin) }

  describe 'GET admin_admins_path' do
    it 'allows admins to see all admins' do
      get admin_admins_path
      expect(response).to be_success
    end
  end

  describe 'PUT unlock_admin_admin_path' do
    let(:locked_admin) { create(:admin, locked: true) }

    it 'unlocks the admin' do
      expect {
        put unlock_admin_admin_path(locked_admin)
      }.to change { locked_admin.reload.locked }.from(true).to(false)
    end
  end
end
