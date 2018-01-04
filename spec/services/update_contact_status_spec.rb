describe UpdateContactStatus do
  describe '#call' do
    let(:contact_list_id) { 5 }
    let(:email) { 'test@test.com' }
    let(:dynamo_db) { instance_double DynamoDB }

    before do
      expect(DynamoDB).to receive(:new).and_return dynamo_db
    end

    context 'when there is no error' do
      let(:status) { :synced }

      it "updates DynamoDB item's status" do
        expect(dynamo_db).to receive(:update_item)
          .with(
            a_hash_including(
              table_name: 'test_contacts',
              attribute_updates: {
                status: {
                  value: status,
                  action: 'PUT'
                }
              }
            )
          )

        UpdateContactStatus.new(contact_list_id, email, status).call
      end
    end

    context 'when there is an error' do
      let(:status) { :error }
      let(:error) { 'Error' }

      it "updates DynamoDB item's status" do
        expect(dynamo_db).to receive(:update_item)
          .with(
            a_hash_including(
              table_name: 'test_contacts',
              attribute_updates: {
                status: {
                  value: status,
                  action: 'PUT'
                },
                error: {
                  value: error,
                  action: 'PUT'
                }
              }
            )
          )

        UpdateContactStatus.new(contact_list_id, email, status, error: error).call
      end
    end
  end
end
