class FetchContactListTotals
  def initialize(site, id: nil)
    @site = site
    @id = id
  end

  # @return [Hash] contact_list.id => total
  def call
    return {} if contact_list_ids.blank?
    reduce process dynamo_db.batch_get_item(request)
  end

  private

  attr_reader :site, :id

  def reduce(result)
    id.present? ? result.fetch(id.to_i, 0) : result
  end

  def process(response)
    response.fetch(table_name, []).inject({}) do |result, item|
      result.update item['lid'].to_i => item['t'].to_i
    end
  end

  def request
    {
      request_items: {
        table_name => {
          keys: contact_list_ids.map { |id| { 'lid' => id, 'email' => 'total' } },
          projection_expression: 'lid,t'
        }
      },
      return_consumed_capacity: 'TOTAL'
    }
  end

  def contact_list_ids
    @contact_list_ids ||= site.contact_lists.ids
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_context: site.contact_lists.order(:updated_at).last.cache_key)
  end
end
