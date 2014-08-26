require "./config/initializers/settings"
require "./lib/hello/data_api_helper"

module Hello::DataAPI
  class << self

    # Returns total views and conversions for each site_element, by day for n days.
    # For example, if site element with id 123 had a total of 10 views and 3 conversions yesterday,
    # and received 5 more views and 1 more conversion today, the response would look like:
    #
    # lifetime_totals(site, [site_element], 2)
    # => {"123" => [[10, 3], [15, 4]]}
    #
    def lifetime_totals(site, site_elements, num_days = 1, cache_options = {})
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

      site_element_ids = site_elements.map(&:id).sort

      cache_key = "hello:data-api:#{site.id}:#{site_element_ids.join('-')}:lifetime_totals:#{num_days}days"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        path, params = Hello::DataAPIHelper::RequestParts.lifetime_totals(site.id, site_element_ids, site.read_key, num_days)
        get(path, params)
      end
    end

    # Returns total views and conversions for each site element, by day for n days, grouped by truncated
    # element subtype (ie: all social goals will get grouped together).
    #
    # lifetime_totals_by_type(site, site.site_elements, 2)
    # => {
    #      :total =>   [[9, 3], [12, 6]],
    #      :email =>   [[3, 1], [4, 2]],
    #      :traffic => [[3, 1], [4, 2]],
    #      :social =>  [[3, 1], [4, 2]]
    #    }
    #
    def lifetime_totals_by_type(site, site_elements, num_days = 30, cache_options = {})
      data = Hello::DataAPI.lifetime_totals(site, site.site_elements, num_days, cache_options) || {}
      totals = {:total => [], :email => [], :social => [], :traffic => []}
      elements = site.site_elements.where(:id => data.keys)

      return totals if data == {}

      # collect the ids of each group
      ids = {
        :total => data.keys,
        :email => elements.select{|e| e.element_subtype == "email"}.map{|e| e.id.to_s},
        :traffic => elements.select{|e| e.element_subtype == "traffic"}.map{|e| e.id.to_s},
        :social => elements.select{|e| e.element_subtype =~ /social\//}.map{|e| e.id.to_s}
      }

      # loop for the number of days of data, based on what came back from the API
      data.values.first.count.times do |i|
        # sum the values for day i in each row of data and shovel that array into totals
        totals[:total] << data.inject([0, 0]) do |sum, data_row|
          day_i_data = data_row[1][i]
          [sum[0] + day_i_data[0], sum[1] + day_i_data[1]]
        end

        # do the same for each subset of data, grouped by element subtype
        [:email, :traffic, :social].each do |key|
          type_data = data.select{|k, v| ids[key].include?(k)}
          totals[key] << type_data.inject([0, 0]) do |sum, data_row|
            day_i_data = data_row[1][i]
            [sum[0] + day_i_data[0], sum[1] + day_i_data[1]]
          end
        end
      end

      totals
    end

    # Returns the total subscribers for each contact list
    #
    # contact_list_totals(site, site.contact_lists)
    # => {"1" => 141, "2" => 951}
    #
    def contact_list_totals(site, contact_lists, cache_options = {})
      contact_list_ids = contact_lists.map(&:id).sort

      cache_key = "hello:data-api:#{site.id}:#{contact_list_ids.join('-')}:contact_list_totals"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        path, params = Hello::DataAPIHelper::RequestParts.contact_list_totals(site.id, contact_list_ids, site.read_key)
        get(path, params)
      end
    end

    # Returns groups of segments and their view/conversion data, grouped by opportunity
    #
    # suggested_opportunities(site, site.site_elements)
    # => {
    #      "high traffic, low conversion" =>  [["co:USA", 100, 10], ["dv:Mobile", 200, 20]],
    #      "low traffic, high conversion" =>  [["co:USA", 100, 10], ["dv:Mobile", 200, 20]],
    #      "high traffic, high conversion" => [["co:USA", 100, 10], ["dv:Mobile", 200, 20]]
    #    }
    #
    def suggested_opportunities(site, site_elements, cache_options = {})
      site_element_ids = site_elements.map(&:id).sort

      cache_key = "hello:data-api:#{site.id}:#{site_element_ids.join('-')}:suggested_opportunities"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        path, params = Hello::DataAPIHelper::RequestParts.suggested_opportunities(site.id, site_element_ids, site.read_key)
        get(path, params)
      end
    end

    # Return name, email and timestamp of subscribers for a contact list
    #
    # get_contacts(contact_list)
    # => [["person100@gmail.com", "person name", 1388534400], ["person99@gmail.com", "person name", 1388534399]]
    #
    def get_contacts(contact_list, from_timestamp = nil, cache_options = {})
      cache_key = "hello:data-api:#{contact_list.site_id}:contact_list-#{contact_list.id}:from#{from_timestamp}"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        path, params = Hello::DataAPIHelper::RequestParts.get_contacts(contact_list.site_id, contact_list.id, contact_list.site.read_key, nil, from_timestamp)
        get(path, params)
      end
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
