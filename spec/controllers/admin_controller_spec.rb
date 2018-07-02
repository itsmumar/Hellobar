describe AdminController, '#require_admin' do
  controller do
    before_action :require_admin

    def index
      render nothing: true
    end
  end

  let(:admin) { create :admin }

  it 'redirects the user to the admin login path when there is no current_admin' do
    get :index

    expect(response).to redirect_to(admin_access_path)
  end
end
