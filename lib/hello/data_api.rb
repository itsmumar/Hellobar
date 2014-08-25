require "./config/initializers/settings"
require "./lib/hello/data_api_helper"

module Hello::DataAPI
  class << self
    def lifetime_totals(site, site_elements, num_days = 1)
      if Hellobar::Settings[:fake_data_api]
        return {}.tap do |hash|
          site_elements.each do |el|
            hash[el.id.to_s] = [[rand(100) + 100, rand(100)]]

            (num_days - 1).times do
              last = hash[el.id.to_s].last
              hash[el.id.to_s] << [last[0] + rand(100) + 100, last[1] + rand(100)]
            end
          end
        end
      end

      path, params = Hello::DataAPIHelper::RequestParts.lifetime_totals(site.id, site_elements.map(&:id), site.read_key, num_days)
      get(path, params)
    end

    def lifetime_totals_by_type(site, site_elements, num_days = 30)
      data = Hello::DataAPI.lifetime_totals(site, site.site_elements, num_days) || {}
      totals = {:total => [], :email => [], :social => [], :traffic => []}
      elements = site.site_elements.where(:id => data.keys)

      return totals if data == {}

      ids = {
        :total => data.keys,
        :email => elements.select{|e| e.element_subtype == "email"}.map{|e| e.id.to_s},
        :traffic => elements.select{|e| e.element_subtype == "traffic"}.map{|e| e.id.to_s},
        :social => elements.select{|e| e.element_subtype =~ /social\//}.map{|e| e.id.to_s}
      }

      data.values.first.count.times do |i|
        totals[:total] << data.inject([0, 0]){|m, d| [m[0] + d[1][i][0], m[1] + d[1][i][1]]}

        [:email, :traffic, :social].each do |key|
          type_data = data.select{|k, v| ids[key].include?(k)}
          totals[key] << type_data.inject([0, 0]){|m, d| [m[0] + d[1][i][0], m[1] + d[1][i][1]]}
        end
      end

      totals
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
