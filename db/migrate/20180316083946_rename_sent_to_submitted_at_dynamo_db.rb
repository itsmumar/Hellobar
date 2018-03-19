class RenameSentToSubmittedAtDynamoDb < ActiveRecord::Migration
  def up
    puts "migrating `#{ table_name }`"

    i = 0
    scan_table do |record|
      i += 1
      next unless record.has_key? 'sent'
      rename_column('sent', 'submitted', record)
      puts "#{ i } records are processed" if (i % 1000).zero?
    end

    puts "#{ i } records are processed"
  end

  def down
    # do nothing
  end

  private

  def table_name
    DynamoDB.email_statictics_table_name
  end

  def scan_table
    request = { table_name: table_name }

    loop do
      response = dynamo.scan(request)
      records, last_evaluated_key =
        response.items, response.last_evaluated_key

      records.each do |record|
        yield record
      end

      break unless last_evaluated_key
      request = request.merge(exclusive_start_key: last_evaluated_key)
    end
  end

  def rename_column(column, new_column, record)
    dynamo.update_item(
      key: record.slice('id', 'type'),
      expression_attribute_names: {
        '#N' => new_column,
        '#O' => column
      },
      update_expression: 'SET #N = #O REMOVE #O',
      table_name: table_name
    )
  end

  def dynamo
    @dynamo ||= DynamoDB.new
  end
end
