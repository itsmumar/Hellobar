describe Admin::UsersController do
  let!(:admin) { create(:admin) }
  let!(:site) { create(:site, :with_user) }
  let(:user) { site.owners.last }

  describe 'GET admin_users_path' do
    before(:each) { stub_current_admin(admin) }
    let(:q) { site.url }
    let(:index) { get admin_users_path(q: q) }

    shared_examples 'success response' do
      before { index }

      it 'renders list with target user' do
        expect(response).to be_success
        expect(response.body).not_to include 'none found'
        expect(response.body).to include user.email
        expect(response.body).to include admin_user_path(user)
      end
    end

    it_behaves_like 'success response'

    context 'without search string' do
      let(:q) { nil }

      it_behaves_like 'success response'
    end

    context 'with empty search string' do
      let(:q) { '' }

      it_behaves_like 'success response'
    end

    context 'with deleted user' do
      let!(:user) { create :user, :deleted, email: 'test@test.com' }
      let(:q) { 'test' }

      it_behaves_like 'success response'
    end

    context 'when finding users by script' do
      let(:q) { site.script_name }

      it_behaves_like 'success response'
    end
  end

  describe 'GET admin_user_path' do
    let(:user) { create :user }

    before do
      stub_current_admin(admin)
    end

    it 'shows the specified user' do
      get admin_user_path(user)

      expect(response).to be_success
      expect(response.body).to include user.email
    end

    context 'with deleted user' do
      let(:user) { create :user, :deleted, email: 'test@test.com' }

      it 'shows a deleted users' do
        get admin_user_path(user)

        expect(response).to be_success
        expect(response.body).to include user.email
      end
    end
  end

  describe 'impersonate and uninpersonate' do
    let(:user) { create(:user) }

    it 'allows the admin to stop impersonating a user' do
      stub_current_admin(admin)

      post admin_impersonate_user_path(user)

      expect(response).to redirect_to new_site_path
      expect(session[:impersonated_user]).to eql user.id

      delete admin_unimpersonate_user_path

      expect(response).to redirect_to admin_users_path
      expect(session[:impersonated_user]).to be_nil
    end
  end

  describe 'DELETE admin_user_path' do
    let(:user) { create(:user) }

    it 'allows the admin to (soft) destroy a user' do
      stub_current_admin(admin)
      delete admin_user_path(user)

      expect(User.only_deleted).to include(user)
    end
  end
end
