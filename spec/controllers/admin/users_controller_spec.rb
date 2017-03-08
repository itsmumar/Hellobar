require 'spec_helper'

describe Admin::UsersController do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
  end

  describe 'GET #index' do
    before(:each) do
      stub_current_admin(@admin)
    end

    it 'allows admins to search users by site URL' do
      get :index, q: 'zombo.com'

      expect(assigns(:users).include?(sites(:zombo).owners.first)).to be_true
    end

    it 'finds deleted users' do
      user = User.create email: 'test@test.com', password: 'supers3cr37'
      user.destroy
      get :index, q: 'test'

      expect(assigns(:users).include?(user)).to be_true
    end

    it 'finds users by script' do
      user = create(:user)
      site = create(:site)
      user.sites << site
      get :index, q: site.script_name

      expect(assigns(:users).include?(user)).to be_true
    end
  end

  describe 'GET #show' do
    before do
      stub_current_admin(@admin)
    end

    it 'shows the specified user' do
      user = users(:joey)
      get :show, id: user.id

      expect(assigns(:user)).to eq(user)
    end

    it 'shows a deleted users' do
      user = User.create email: 'test@test.com', password: 'supers3cr37'
      user.destroy
      get :show, id: user.id

      expect(assigns(:user)).to eq(user)
    end
  end

  describe 'POST #impersonate' do
    it 'allows the admin to impersonate a user' do
      stub_current_admin(@admin)

      post :impersonate, id: users(:joey)

      expect(controller.current_user).to eq(users(:joey))
    end
  end

  describe 'DELETE #unimpersonate' do
    it 'allows the admin to stop impersonating a user' do
      stub_current_admin(@admin)

      post :impersonate, id: users(:joey)

      expect(controller.current_user).to eq(users(:joey))

      delete :unimpersonate

      expect(controller.current_user).to be_nil
    end
  end

  describe 'DELETE #destroy' do
    it 'allows the admin to (soft) destroy a user' do
      stub_current_admin(@admin)
      user = users(:wootie)

      delete :destroy, id: user

      expect(User.only_deleted).to include(user)
    end
  end
end
