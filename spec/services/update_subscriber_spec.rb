describe UpdateSubscriber do
  let(:contact_list) { create :contact_list }
  let(:email) { 'email@example.com' }
  let(:params) { Hash[email: 'newemail@example.com', name: 'Name'] }
  let(:service) { UpdateSubscriber.new(contact_list, email, params) }

  before { allow(CreateSubscriber).to receive_service_call }
  before { allow(DeleteSubscriber).to receive_service_call }

  it 'deletes record' do
    expect(DeleteSubscriber)
      .to receive_service_call
      .with(contact_list, email)

    service.call
  end

  it 'creates new record' do
    expect(CreateSubscriber)
      .to receive_service_call
      .with(contact_list, params)

    service.call
  end
end
