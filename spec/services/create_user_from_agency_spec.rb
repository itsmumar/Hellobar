describe CreateUserFromAgency do
  let(:params) do
    Hash[
      email: 'test@testing.com',
      password: '12345678',
      name: 'mr test',
      agency_name: 'agency1',
      url: 'testingtesting.com'
    ]
  end

  let(:service) do
    CreateUserFromAgency.new(Hash[
      email: 'test@testing.com',
      password: '12345678',
      name: 'mr test',
      agency_name: 'agency1',
      url: 'testingtesting.com'
    ])
  end

  it 'calls Outside Services' do
    expect(CreateUser).to receive_service_call
    expect(CreateSite).to receive_service_call
    expect(ChangeSubscription).to receive_service_call

    service.call
  end
end
