class FetchContactListTotals
  def initialize(site, id: nil)
    @site = site
    @id = id
  end

  def call
    return {} if contact_list_ids.blank?
    reduce process DynamoDB.new(cache_key: cache_key, expires_in: 1.hour).batch_fetch(request)
  end

  private

  attr_reader :site, :id

  def reduce(result)
    id.present? ? result.fetch(id.to_i, 0) : result
  end

  def process(response)
    response.fetch(table, []).inject({}) do |result, item|
      result.update item['lid'].to_i => item['t'].to_i
    end
  end

  def cache_key
    site.cache_key
  end

  def request
    {
      request_items: {
        table => {
          keys: contact_list_ids.map { |id| { 'lid' => id, 'email' => 'total' } },
          projection_expression: 'lid,t'
        }
      }
    }
  end

  def contact_list_ids
    @contact_list_ids ||= site.contact_lists.ids
  end

  def table
    Rails.env.production? ? 'contacts' : 'edge_contacts'
  end
end
