describe CreateUserFromForm do
  let(:params) do
    Hash[email: 'email@example.com', password: 'password', site_url: 'google.com']
  end

  let(:form) { RegistrationForm.new(registration_form: params) }
  let(:service) { CreateUserFromForm.new(form) }

  it 'validates the form' do
    expect(form).to receive(:validate!)
    service.call
  end

  it 'creates user' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'calls CreateUser service' do
    expect(CreateUser).to receive_service_call.with(form.user)
    service.call
  end

  it 'returns the user' do
    user = service.call
    expect(user).to eql form.user
    expect(user).to be_a User
    expect(user).to be_persisted
  end
end
