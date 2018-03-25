describe CreateSubscriber do
  let(:contact_list) { create :contact_list }
  let(:params) { Hash[email: 'email@example.com', name: 'Name'] }
  let(:dynamo) { double('DynamoDB') }
  let(:response) { double('response', attributes: {}) }
  let(:service) { CreateSubscriber.new(contact_list, params) }

  before { allow(DynamoDB).to receive(:new).and_return(dynamo) }
  before { allow(UpdateSubscribersCounter).to receive_service_call }
  before { allow(dynamo).to receive(:put_item).and_return(response) }

  it 'puts item to dynamodb', :freeze do
    expect(dynamo).to receive(:put_item).with(
      item: {
        lid: contact_list.id,
        email: params[:email],
        n: params[:name],
        ts: Time.current.to_i
      },
      return_consumed_capacity: 'TOTAL',
      return_values: 'ALL_OLD',
      table_name: 'test_contacts'
    ).and_return(response)

    service.call
  end

  it 'updates counter' do
    expect(UpdateSubscribersCounter)
      .to receive_service_call.with(contact_list.id, value: 1)
    service.call
  end

  it 'invalidates dynamo db cache related to the contact list' do
    expect(contact_list).to receive(:touch)
    service.call
  end

  it 'returns new record', :freeze do
    expect(service.call).to eql(
      lid: contact_list.id,
      email: params[:email],
      n: params[:name],
      ts: Time.current.to_i
    )
  end

  context 'when name is blank' do
    let(:params) { { email: 'email@example.com', name: '' } }

    it 'filters it out' do
      expect(dynamo).to receive(:put_item).with(
        item: {
          lid: contact_list.id,
          email: params[:email],
          ts: Time.current.to_i
        },
        return_consumed_capacity: 'TOTAL',
        return_values: 'ALL_OLD',
        table_name: 'test_contacts'
      ).and_return(response)

      service.call
    end

    it 'returns new record without a name', :freeze do
      expect(service.call).to eql(
        lid: contact_list.id,
        email: params[:email],
        ts: Time.current.to_i
      )
    end
  end
end
