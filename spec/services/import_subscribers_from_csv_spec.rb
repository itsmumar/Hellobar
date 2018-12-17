describe ImportSubscribersFromCsv do
  let(:contact_list) { create :contact_list }
  let(:uploaded_file) { Rails.root.join('spec', 'fixtures', 'subscribers.csv').open }
  let(:service) { ImportSubscribersFromCsv.new(uploaded_file, contact_list) }

  it 'calls CreateSubscriber for each row in the csv file' do
    expect(CreateSubscriber)
      .to receive_service_call(contact_list, email: 'email', name: 'name')

    (1..4).each do |n|
      expect(CreateSubscriber)
        .to receive_service_call(
          contact_list,
          email: "email#{ n }@example.com",
          name: "Name#{ n }"
        )
    end
    service.call
  end

  context 'when CreateSubscriber::InvalidEmailError is raised' do
    it 'ignores the error' do
      expect(CreateSubscriber)
        .to receive_service_call
        .exactly(5)
        .times
        .and_raise(CreateSubscriber::InvalidEmailError.new('email'))

      expect { service.call }.not_to raise_error
    end
  end
end
