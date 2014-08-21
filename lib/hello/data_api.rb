require "./lib/hello/data_api_helper"

module Hello::DataAPI
  class << self
    def lifetime_totals(site, site_elements, num_days = 1)
      path, params = Hello::DataAPIHelper::RequestParts.lifetime_totals(site.id, site_elements.map(&:id), site.read_key, num_days)
      get(path, params)
    end

    def contact_list_totals(site, contact_lists)
      path, params = Hello::DataAPIHelper::RequestParts.contact_list_totals(site.id, contact_lists.map(&:id), site.read_key)
      get(path, params)
    end

    def suggested_opportunities(site, site_elements)
      path, params = Hello::DataAPIHelper::RequestParts.suggested_opportunities(site.id, site_elements.map(&:id), site.read_key)
      get(path, params)
    end

    def get_contacts(contact_list, from_timestamp = nil)
      path, params = Hello::DataAPIHelper::RequestParts.get_contacts(contact_list.site_id, contact_list.id, contact_list.site.read_key, nil, from_timestamp)
      get(path, params)
    end

    def get(path, params)
      url = URI.join(Hellobar::Settings[:data_api_url], Hello::DataAPIHelper.url_for(path, params)).to_s
      response = Net::HTTP.get(URI.parse(url))
      JSON.parse(response)
    rescue JSON::ParserError, SocketError
      Rails.logger.error("Data API Error: #{response}")
      return nil
    end
  end
end
