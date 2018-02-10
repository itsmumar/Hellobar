describe 'api/subscribers requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:contact_list) { create :contact_list, site: site }
  let(:headers) { api_headers_for_user(user) }
  let(:params) { Hash[format: :json] }

  let(:subscribers) do
    [
      {
        'lid' => '1',
        'email' => 'email@example.com',
        'n' => 'Name',
        'ts' => Time.current.to_i
      }
    ]
  end

  let(:dynamo_client) do
    instance_double(DynamoDB,
      query_enum: subscribers,
      update_item: Aws::DynamoDB::Types::UpdateItemOutput.new,
      put_item: Aws::DynamoDB::Types::PutItemOutput.new,
      delete_item: Aws::DynamoDB::Types::DeleteItemOutput.new)
  end

  before do
    allow(DynamoDB).to receive(:new).and_return(dynamo_client)
  end

  describe 'GET #index' do
    let(:subscriber_params) { Hash[name: 'Name', email: 'email@example.com'] }

    it 'responds with success' do
      query = hash_including(
        expression_attribute_values: { ':lidValue' => contact_list.id },
        projection_expression: 'email,n,ts,lid,#s,#e'
      )

      expect(dynamo_client)
        .to receive(:query_enum)
        .with(query, fetch_all: false)
        .and_return({})

      get api_site_contact_list_subscribers_path(site, contact_list),
        params,
        headers

      expect(response).to be_successful
    end
  end

  describe 'POST #create', :freeze do
    let(:subscriber_params) { Hash[name: 'Name', email: 'email@example.com'] }

    def send_request
      post api_site_contact_list_subscribers_path(site, contact_list),
        params.merge(subscriber: subscriber_params),
        headers
    end

    it 'puts new subscriber into dynamodb' do
      put_item_query = hash_including(
        item: {
          lid: contact_list.id,
          email: subscriber_params[:email],
          n: subscriber_params[:name],
          ts: Time.current.to_i
        },
        return_values: 'ALL_OLD'
      )

      expect(dynamo_client)
        .to receive(:put_item)
        .with(put_item_query)
        .and_return(Aws::DynamoDB::Types::PutItemOutput.new)

      send_request

      expect(response).to be_successful
    end

    it 'updates subscribers counter' do
      update_item_query = hash_including(
        key: {
          lid: contact_list.id,
          email: 'total'
        },
        attribute_updates: {
          t: {
            value: 1,
            action: 'ADD'
          }
        }
      )

      expect(dynamo_client)
        .to receive(:update_item)
        .with(update_item_query)
        .and_return(Aws::DynamoDB::Types::UpdateItemOutput.new)

      send_request

      expect(response).to be_successful
    end
  end

  describe 'PATCH #update', :freeze do
    let(:email) { 'email@example.com' }
    let(:subscriber_params) { Hash[name: 'Name', email: 'newemail@example.com'] }

    def send_request
      patch api_site_contact_list_subscriber_path(site, contact_list, email: email),
        params.merge(email: email, subscriber: subscriber_params),
        headers
    end

    it 'deletes existing subscriber' do
      query = hash_including(
        key: {
          lid: contact_list.id,
          email: email
        },
        return_values: 'ALL_OLD'
      )

      expect(dynamo_client)
        .to receive(:delete_item)
        .with(query)
        .and_return(
          Aws::DynamoDB::Types::DeleteItemOutput.new(attributes: { email: email })
        )

      send_request

      expect(response).to be_successful
    end

    context 'when subscriber has been deleted' do
      before do
        allow(dynamo_client)
          .to receive(:delete_item)
          .and_return(
            Aws::DynamoDB::Types::DeleteItemOutput.new(attributes: { email: email })
          )
      end

      it 'decrements subscribers counter' do
        query = hash_including(
          key: {
            lid: contact_list.id,
            email: 'total'
          },
          attribute_updates: {
            t: {
              value: -1,
              action: 'ADD'
            }
          }
        )

        expect(dynamo_client)
          .to receive(:update_item)
          .with(query)
          .and_return(Aws::DynamoDB::Types::UpdateItemOutput.new)

        send_request

        expect(response).to be_successful
      end
    end

    it 'puts new subscriber' do
      query = hash_including(
        item: {
          lid: contact_list.id,
          email: subscriber_params[:email],
          n: subscriber_params[:name],
          ts: Time.current.to_i
        },
        return_values: 'ALL_OLD'
      )

      expect(dynamo_client)
        .to receive(:put_item)
        .with(query)
        .and_return(Aws::DynamoDB::Types::PutItemOutput.new)

      send_request

      expect(response).to be_successful
    end

    it 'increments subscribers counter' do
      query = hash_including(
        key: {
          lid: contact_list.id,
          email: 'total'
        },
        attribute_updates: {
          t: {
            value: 1,
            action: 'ADD'
          }
        }
      )

      expect(dynamo_client)
        .to receive(:update_item)
        .with(query)
        .and_return(Aws::DynamoDB::Types::UpdateItemOutput.new)

      send_request

      expect(response).to be_successful
    end
  end

  describe 'DELETE #destroy' do
    let(:email) { 'email@example.com' }
    let(:subscriber_params) { Hash[name: 'Name', email: 'newemail@example.com'] }

    def send_request
      delete api_site_contact_list_subscriber_path(site, contact_list, email: email),
        params.merge(email: email, subscriber: subscriber_params),
        headers
    end

    it 'deletes subscriber' do
      query = hash_including(
        key: {
          lid: contact_list.id,
          email: email
        },
        return_values: 'ALL_OLD'
      )

      expect(dynamo_client).to receive(:delete_item).with(query)

      send_request

      expect(response).to be_successful
    end

    context 'when subscriber has been deleted' do
      before do
        allow(dynamo_client)
          .to receive(:delete_item)
          .and_return(
            Aws::DynamoDB::Types::DeleteItemOutput.new(attributes: { email: email })
          )
      end

      it 'decrements subscribers counter' do
        query = hash_including(
          key: {
            lid: contact_list.id,
            email: 'total'
          },
          attribute_updates: {
            t: {
              value: -1,
              action: 'ADD'
            }
          }
        )

        expect(dynamo_client)
          .to receive(:update_item)
          .with(query)
          .and_return(Aws::DynamoDB::Types::UpdateItemOutput.new)

        send_request

        expect(response).to be_successful
      end
    end
  end
end
