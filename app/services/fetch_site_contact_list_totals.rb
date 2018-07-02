class FetchSiteContactListTotals
  MAX_QUERIES_IN_BATCH = 100

  def initialize(site, contact_list_ids = nil)
    @site = site
    @contact_list_ids = (contact_list_ids || site.contact_lists.ids).compact.map(&:to_i)
  end

  # @return [Hash] contact_list.id => total
  def call
    return {} if contact_list_ids.blank?

    reduce(fetch)
  end

  private

  attr_reader :site, :contact_list_ids

  def fetch
    contact_list_ids.in_groups_of(MAX_QUERIES_IN_BATCH, false).flat_map do |batch|
      dynamo_db.batch_get_item(request(batch)).fetch(table_name, [])
    end
  end

  def reduce(data)
    data.each_with_object(Hash.new { 0 }) do |item, result|
      result[item['lid'].to_i] = item['t'].to_i
    end
  end

  def request(ids)
    {
      request_items: {
        table_name => {
          keys: ids.map { |id| { 'lid' => id, 'email' => 'total' } },
          projection_expression: 'lid,t'
        }
      },
      return_consumed_capacity: 'TOTAL'
    }
  end

  def table_name
    DynamoDB.contacts_table_name
  end

  def dynamo_db
    DynamoDB.new(cache_context: site.contact_lists.reorder(:updated_at).last.cache_key)
  end
end
