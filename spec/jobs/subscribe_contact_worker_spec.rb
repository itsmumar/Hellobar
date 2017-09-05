describe SubscribeContactWorker do
  let(:job) { described_class }
  let(:contact) { described_class::Contact.new('1', 'email@example.com', 'firstname,lastname') }

  def make_contact(id, email, fields)
    SubscribeContactWorker::Contact.new(id, email, fields)
  end

  describe '.perform_now' do
    it 'parses message and calls #subscribe' do
      expect(SubscribeContact).to receive_service_call.with(contact)
      job.perform_now 'contact_list:sync_one[1,"email@example.com","firstname,lastname"]'
    end
  end

  describe '.parse' do
    let(:contact) { job.parse(message) }

    context 'with id, email and one field' do
      let(:message) { 'contact_list:sync_one[1,"email@example.com","firstname"]' }

      it 'returns instance of Contact' do
        expect(contact).to eql make_contact('1', 'email@example.com', 'firstname')
      end
    end

    context 'with id, email and few fields' do
      let(:message) { 'contact_list:sync_one[1,"email@example.com", "firstname,lastname,gender"]' }

      it 'returns instance of Contact' do
        expect(contact).to eql make_contact('1', 'email@example.com', 'firstname,lastname,gender')
      end
    end

    context 'when email is empty string' do
      let(:message) { 'contact_list:sync_one[1,"","firstname"]' }

      it 'returns instance of Contact' do
        expect(contact).to eql make_contact('1', '', 'firstname')
      end
    end

    context 'when email is nil' do
      let(:message) { 'contact_list:sync_one[1,nil,"firstname"]' }

      it 'returns instance of Contact' do
        expect(contact).to eql make_contact('1', 'nil', 'firstname')
      end
    end

    context 'without fields' do
      let(:message) { 'contact_list:sync_one[1, "email@example.com", nil]' }

      it 'returns instance of Contact' do
        expect(contact).to eql make_contact('1', 'email@example.com', 'nil')
      end
    end
  end

  describe '#perform' do
    let(:sqs_msg) { double('sqs_msg', delete: true, body: 'sqs msg body', queue_name: 'a queue') }
    let(:perform) { job.new.perform(sqs_msg, contact) }

    it 'calls on SyncOneContactList' do
      expect(SubscribeContact).to receive_service_call.with(contact)
      perform
    end

    context 'when email is blank' do
      let(:contact) { described_class::Contact.new(1, ' ', 'firstname,lastname') }

      it 'raises "Cannot sync without email present"' do
        expect(sqs_msg).to receive(:delete)
        expect(SubscribeContact).not_to receive_service_call
        perform
      end
    end

    context 'when error is raised' do
      before { expect(SubscribeContact).to receive_service_call.with(contact).and_raise(StandardError) }

      it 'deletes sqs_msg' do
        expect(sqs_msg).to receive(:delete)
        perform
      end

      it 'sends exception to Raven' do
        extra = { arguments: ['sqs msg body', contact], queue_name: 'a queue' }
        expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), extra: extra)
        perform
      end
    end
  end

  describe SubscribeContactWorker::Contact do
    describe '.fields' do
      let(:contact) { make_contact('1', 'email@example.com', ' firstname lastname ') }

      it 'returns striped fields' do
        expect(contact.fields).to eql 'Firstname Lastname'
      end

      context 'when fields is "nil"' do
        let(:contact) { make_contact('1', 'email@example.com', ' nil ') }

        it 'returns nil' do
          expect(contact.fields).to be_nil
        end
      end

      context 'when fields is empty string' do
        let(:contact) { make_contact('1', 'email@example.com', ' ') }

        it 'returns nil' do
          expect(contact.fields).to be_nil
        end
      end
    end

    describe '.email' do
      let(:contact) { make_contact('1', ' email@example.com ', '') }

      it 'returns striped email' do
        expect(contact.email).to eql 'email@example.com'
      end

      context 'when email is "nil"' do
        let(:contact) { make_contact('1', ' nil ', 'nil') }

        it 'returns nil' do
          expect(contact.email).to be_nil
        end
      end

      context 'when fields is empty string' do
        let(:contact) { make_contact('1', ' ', ' ') }

        it 'returns nil' do
          expect(contact.email).to be_nil
        end
      end
    end

    describe '.contact_list' do
      let!(:contact_list) { create :contact_list }
      let(:contact) { make_contact(contact_list.id, ' email@example.com ', '') }

      it 'returns contact list' do
        expect(contact.contact_list).to eql contact_list
      end

      context 'when contact list not found' do
        let(:contact) { make_contact(999, ' email@example.com ', '') }

        it 'raises ActiveRecord::RecordNotFound' do
          expect { contact.contact_list }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
