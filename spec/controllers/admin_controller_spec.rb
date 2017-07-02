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

  it 'redirects the user to the reset password path if they need to set a new password' do
    allow(admin).to receive(:needs_to_set_new_password?).and_return(true)
    allow(controller).to receive(:current_admin).and_return(admin)
    allow(controller).to receive(:url_for).and_return('http://google.com')

    get :index

    expect(response).to redirect_to(admin_reset_password_path)
  end

  it 'does not redirect if the user needs to reset their password and is currently on the page' do
    allow(admin).to receive(:needs_to_set_new_password?).and_return(true)
    allow(controller).to receive(:current_admin).and_return(admin)
    allow(controller).to receive(:url_for).and_return(admin_reset_password_path)

    get :index

    expect(response).not_to be_redirect
  end
end
