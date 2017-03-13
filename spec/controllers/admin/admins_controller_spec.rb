require 'spec_helper'

describe Admin::AdminsController do
  let!(:admin) { create(:admin) }
  before(:each) { stub_current_admin(admin) }

  describe 'GET #index' do
    it 'allows admins to see all admins' do
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
