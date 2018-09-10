describe CreateUserFromForm do
  let(:params) do
    Hash[email: 'email@example.com', password: 'password', site_url: 'abcdefg.com']
  end

  let(:cookies) { Hash[tap_vid: 'vid', tap_aid: 'aid'] }
  let(:form) { RegistrationForm.new(registration_form: params) }
  let(:service) { CreateUserFromForm.new(form, cookies) }

  it 'validates the form' do
    expect(form).to receive(:validate!)
    service.call
  end

  it 'creates user' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'calls CreateUser service' do
    expect(CreateUser).to receive_service_call.with(form.user, cookies)
    service.call
  end

  it 'creates the user and returns it' do
    user = service.call

    expect(user).to eql form.user
    expect(user).to be_a User
    expect(user).to be_persisted
  end
end
