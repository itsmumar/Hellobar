describe Admin::UsersController do
  let!(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user) }

  describe 'GET #index' do
    before(:each) { stub_current_admin(admin) }

    it 'allows admins to search users by site URL' do
      get :index, q: site.url

      expect(assigns(:users).include?(site.owners.first)).to be_truthy
    end

    it 'finds deleted users' do
      user = User.create email: 'test@test.com', password: 'supers3cr37'
      user.destroy
      get :index, q: 'test'

      expect(assigns(:users).include?(user)).to be_truthy
    end

    it 'finds users by script' do
      user = create(:user)
      site = create(:site)
      user.sites << site
      get :index, q: site.script_name

      expect(assigns(:users).include?(user)).to be_truthy
    end
  end

  describe 'GET #show' do
    before do
      stub_current_admin(admin)
    end

    it 'shows the specified user' do
      user = create(:user)
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
    let(:user) { create(:user) }

    it 'allows the admin to impersonate a user' do
      stub_current_admin(admin)

      post :impersonate, id: user

      expect(controller.current_user).to eql user
    end
  end

  describe 'DELETE #unimpersonate' do
    let(:user) { create(:user) }

    it 'allows the admin to stop impersonating a user' do
      stub_current_admin(admin)

      post :impersonate, id: user

      expect(controller.current_user).to eql user

      delete :unimpersonate

      expect(controller.current_user).to be_nil
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }

    it 'allows the admin to (soft) destroy a user' do
      stub_current_admin(admin)
      delete :destroy, id: user
      expect(User.only_deleted).to include(user)
    end
  end
end
