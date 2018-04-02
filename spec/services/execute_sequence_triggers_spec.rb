describe ExecuteSequenceTriggers do
  subject(:service) { described_class.new(email, name, contact_list) }

  let(:name) { 'Ralph' }
  let(:email) { 'r.schwarz@gmail.com' }
  let(:contact_list) { create(:contact_list) }

  let(:sequence) { create(:sequence, contact_list: contact_list) }
  let!(:step1) { create(:sequence_step, sequence: sequence, delay: 1.hour.to_i) }
  let!(:step2) { create(:sequence_step, sequence: sequence, delay: 1.day.to_i) }

  let(:dynamo_db) { instance_double(DynamoDB, put_item: {}, update_item: {}) }

  before do
    allow(DynamoDB).to receive(:new).and_return(dynamo_db)
  end

  it 'create sequence recipient for each step' do
    sequence.steps.each do |step|
      created_at = Time.current.to_i
      scheduled_at = created_at + step.delay

      expect(dynamo_db).to receive(:put_item).with(
        item: {
          step_id: step.id,
          email: email,
          created_at: created_at,
          scheduled_at: scheduled_at
        },
        return_consumed_capacity: 'TOTAL',
        return_values: 'NONE',
        table_name: 'test_sequence_recipients'
      )
    end

    service.call
  end

  it 'enqueues sequence email job for each step' do
    sequence.steps.each do |step|
      scheduled_at = Time.current.to_i + step.delay

      expect(dynamo_db).to receive(:put_item).with(
        item: {
          type: 'sequence',
          identifier: "#{ email }_#{ step.id }_#{ scheduled_at }",
          step_id: step.id,
          email: email,
          name: name,
          executable_type: 'email',
          scheduled_at: scheduled_at,
          email_subject: step.executable.subject,
          email_body: step.executable.body,
          email_from_name: step.executable.from_name,
          email_from_email: step.executable.from_email
        },
        return_consumed_capacity: 'TOTAL',
        return_values: 'NONE',
        table_name: 'test_queues'
      )
    end

    service.call
  end

  context 'when name is nil' do
    let(:name) { nil }

    it 'does not send name to DynamoDB' do
      sequence.steps.each do |step|
        scheduled_at = Time.current.to_i + step.delay

        expect(dynamo_db).to receive(:put_item).with(
          item: {
            type: 'sequence',
            identifier: "#{ email }_#{ step.id }_#{ scheduled_at }",
            step_id: step.id,
            email: email,
            executable_type: 'email',
            scheduled_at: scheduled_at,
            email_subject: step.executable.subject,
            email_body: step.executable.body,
            email_from_name: step.executable.from_name,
            email_from_email: step.executable.from_email
          },
          return_consumed_capacity: 'TOTAL',
          return_values: 'NONE',
          table_name: 'test_queues'
        )
      end

      service.call
    end
  end

  it 'increases `recipients` counter in email statistics for each step' do
    sequence.steps.each do |step|
      expect(dynamo_db).to receive(:update_item).with(
        key: {
          id: step.id,
          type: 'sequence_step'
        },
        expression_attribute_names: {
          '#c' => 'recipients'
        },
        expression_attribute_values: {
          ':increment' => 1
        },
        update_expression: 'ADD #c :increment',
        table_name: 'test_email_statistics'
      )
    end

    service.call
  end

  it 'increases `scheduled` counter in email statistics for each step' do
    sequence.steps.each do |step|
      expect(dynamo_db).to receive(:update_item).with(
        key: {
          id: step.id,
          type: 'sequence_step'
        },
        expression_attribute_names: {
          '#c' => 'scheduled'
        },
        expression_attribute_values: {
          ':increment' => 1
        },
        update_expression: 'ADD #c :increment',
        table_name: 'test_email_statistics'
      )
    end

    service.call
  end
end
