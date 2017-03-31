describe Users::ForgotEmailsController, '#new' do
  it 'renders the template' do
    get :new

    expect(response).to render_template(:new)
  end
end

describe Users::ForgotEmailsController, '#create' do
  let(:params) do
    {
      site_url: 'site.com',
      first_name: 'firstie',
      last_name: 'lastie',
      email: 'la@croix.com'
    }.with_indifferent_access
  end

  it 'delivers the forgot email with the correct parameters' do
    expect(MailerGateway)
      .to receive(:send_email).with('Forgot Email', 'support@hellobar.com', params)

    post :create, params
  end

  it 'redirects to the new_forgot_email_path' do
    post :create, params

    expect(response).to redirect_to(new_forgot_email_path)
  end

  it 'flashes a notice to the user' do
    post :create, params

    expect(flash[:notice]).to be_present
  end
end
