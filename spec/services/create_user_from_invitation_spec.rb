describe CreateUserFromInvitation do
  let(:invitation_token) { 'invitation_token' }
  let(:params) do
    {
      email: 'email@example.com',
      first_name: 'First',
      last_name: 'Last',
      password: '',
      password_confirmation: '',
      timezone: ''
    }
  end
  let(:service) { CreateUserFromInvitation.new(invitation_token, params) }

  let!(:temp_user) { create(:user, invite_token: invitation_token, status: User::TEMPORARY) }

  it 'updates temporary user' do
    expect { service.call }
      .to change { temp_user.reload.status }
      .from(User::TEMPORARY)
      .to(User::ACTIVE)

    expect(temp_user.email).to eql(params[:email])
    expect(temp_user.first_name).to eql(params[:first_name])
    expect(temp_user.last_name).to eql(params[:last_name])
  end

  it 'calls CreateUser service' do
    expect(CreateUser).to receive_service_call.with(temp_user)
    service.call
  end

  it 'returns the user' do
    user = service.call
    expect(user).to eql user
    expect(user).to be_a User
    expect(user).to be_persisted
  end
end
