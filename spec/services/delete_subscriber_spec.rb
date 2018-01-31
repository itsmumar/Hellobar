describe DeleteSubscriber do
  let(:contact_list) { create :contact_list }
  let(:email) { 'email@example.com' }
  let(:dynamo) { double('DynamoDB') }
  let(:response) { double('response', attributes: { lid: contact_list.id, email: email }) }
  let(:service) { DeleteSubscriber.new(contact_list, email) }

  before { allow(DynamoDB).to receive(:new).and_return(dynamo) }
  before { allow(UpdateSubscribersCounter).to receive_service_call }
  before { allow(dynamo).to receive(:delete_item).and_return(response) }

  it 'deletes item in dynamodb', :freeze do
    expect(dynamo).to receive(:delete_item).with(
      key: {
        lid: contact_list.id,
        email: email
      },
      return_consumed_capacity: 'TOTAL',
      return_values: 'ALL_OLD',
      table_name: 'test_contacts'
    ).and_return(response)

    service.call
  end

  it 'updates counter' do
    expect(UpdateSubscribersCounter)
      .to receive_service_call.with(contact_list.id, value: -1)
    service.call
  end

  it 'invalidates dynamo db cache related to the contact list' do
    expect(contact_list).to receive(:touch)
    service.call
  end
end
