class ExecuteSequenceTriggers
  SEQUENCE_TYPE = 'sequence'.freeze
  SEQUENCE_STEP_TYPE = 'sequence_step'.freeze
  EMAIL_EXECUTABLE_TYPE = 'email'.freeze

  def initialize(email, name, contact_list)
    @contact_list = contact_list
    @email = email
    @name = name
  end

  def call
    fetch_sequences.each do |sequence|
      add_contact_to_sequence(sequence)
    end
  end

  private

  attr_reader :email, :name, :contact_list

  def fetch_sequences
    contact_list.sequences
  end

  def add_contact_to_sequence(sequence)
    sequence.steps.each do |step|
      schedule_email_step(step) if step.executable.is_a?(Email)
    end
  end

  def schedule_email_step(step)
    created_at = Time.current.to_i
    scheduled_at = created_at + step.delay

    create_sequence_recipient(step, created_at, scheduled_at)
    enqueue_sequence_step_execution(step, scheduled_at)
    increase_email_statistics(step, :recipients)
    increase_email_statistics(step, :scheduled)
  end

  def create_sequence_recipient(step, created_at, scheduled_at)
    dynamo_db.put_item(
      item: {
        step_id: step.id,
        email: email,
        created_at: created_at,
        scheduled_at: scheduled_at
      },
      return_consumed_capacity: 'TOTAL',
      return_values: 'NONE',
      table_name: DynamoDB.sequence_recipients_table_name
    )
  end

  def enqueue_sequence_step_execution(step, scheduled_at)
    dynamo_db.put_item(
      item: {
        type: SEQUENCE_TYPE,
        identifier: "#{ email }_#{ step.id }_#{ scheduled_at }",
        step_id: step.id,
        email: email,
        executable_type: EMAIL_EXECUTABLE_TYPE,
        scheduled_at: scheduled_at,
        email_subject: step.executable.subject,
        email_body: step.executable.body,
        email_from_name: step.executable.from_name,
        email_from_email: step.executable.from_email
      },
      return_consumed_capacity: 'TOTAL',
      return_values: 'NONE',
      table_name: DynamoDB.queues_table_name
    )
  end

  def increase_email_statistics(step, column)
    dynamo_db.update_item(
      key: {
        id: step.id,
        type: SEQUENCE_STEP_TYPE
      },
      expression_attribute_names: {
        '#c' => column.to_s
      },
      expression_attribute_values: {
        ':increment' => 1
      },
      update_expression: 'ADD #c :increment',
      table_name: DynamoDB.email_statictics_table_name
    )
  end

  def dynamo_db
    DynamoDB.new
  end
end
