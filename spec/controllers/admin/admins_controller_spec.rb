require 'spec_helper'

describe Admin::AdminsController do
  before(:each) do
    @admin = create(:admin)
    stub_current_admin(@admin)
  end

  describe 'GET #index' do
    it 'allows admins to see all admins' do
      create(:admin)
      get :index

      expect(assigns(:admins)).to eq(Admin.all)
    end
  end

  describe 'PUT #unlock' do
    it 'unlocks the admin' do
      admin = create(:admin, locked: true)
      put :unlock, id: admin.id

      expect(admin.reload.locked).to be(false)
    end
  end
end
