require "./config/initializers/settings"
require "./lib/hello/data_api_helper"
require "./lib/hello/api_performance"

module Hello::DataAPI
  class << self
    API_MAX_SLICE = 25

    # Returns total views and conversions for each site_element, by day for n days.
    # For example, if site element with id 123 had a total of 10 views and 3 conversions yesterday,
    # and received 5 more views and 1 more conversion today, the response would look like:
    #
    # lifetime_totals(site, [site_element], 2)
    # => {"123" => [[10, 3], [15, 4]]}
    #
    def lifetime_totals(site, site_elements, num_days = 1, cache_options = {})
      return fake_lifetime_totals(site, site_elements, num_days) if Hellobar::Settings[:fake_data_api]

      site_element_ids = site_elements.map(&:id).sort

      cache_key = "hello:data-api:#{site.id}:#{site_element_ids.sort.join('-')}:lifetime_totals:#{num_days}days:#{site.script_installed_at.to_i}"
      cache_options[:expires_in] = 10.minutes

      api_results = Rails.cache.fetch cache_key, cache_options do
        results = {}
        site_element_ids.each_slice(API_MAX_SLICE) do |ids|
          path, params = Hello::DataAPIHelper::RequestParts.lifetime_totals(site.id, ids, site.read_key, num_days)
          slice_results = get(path, params)
          results.merge!(slice_results) if !slice_results.nil?
        end
        results
      end

      Hash[api_results.map{|k,v| [k, Performance.new(v)] } ]
    end

    def fake_lifetime_totals(site, site_elements, num_days = 1)
      {}.tap do |hash|
        site_elements.each do |el|
          rng = Random.new(el.id)

          hash[el.id.to_s] = [[rng.rand(100) + 100, rng.rand(90)]]

          (num_days - 1).times do
            last = hash[el.id.to_s].last
            hash[el.id.to_s] << [last[0] + rng.rand(101) + 100, last[1] + rng.rand(91)]
          end

          hash[el.id.to_s] = Performance.new(hash[el.id.to_s])
        end
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
      ids = {}

      # collect the ids of each subtype
      [:traffic, :email, :social].each do |key|
        ids[key] = elements.select{|e| e.short_subtype == key.to_s}.map{|e| e.id.to_s}
      end

      # what is the most amount of data (in days) we have for any site element?
      most_days = data.values.map(&:count).sort.last || 0

      # zero-pad all data so that it can be summed conveniently
      data.each do |key, value|
        data[key] = Array.new(most_days - value.count, [0, 0]) + value
      end

      most_days.times do |i|
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

      # remove any zero-padding values that made it through summation
      totals.each do |key, value|
        totals[key] = Performance.new(value.select { |v| v != [0, 0] })
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

      cache_key = "hello:data-api:#{site.id}:#{contact_list_ids.sort.join('-')}:contact_list_totals:#{site.script_installed_at.to_i}"
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
      return fake_suggested_opportunities(site, site_elements) if Hellobar::Settings[:fake_data_api]

      site_element_ids = site_elements.map(&:id).sort

      cache_key = "hello:data-api:#{site.id}:#{site_element_ids.sort.join('-')}:suggested_opportunities"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        results = {}
        site_element_ids.each_slice(API_MAX_SLICE) do |ids|
          path, params = Hello::DataAPIHelper::RequestParts.suggested_opportunities(site.id, ids, site.read_key)
          slice_results = get(path, params)
          if slice_results != nil
            results = results.deep_merge(slice_results) { |key, x, y| x + y }
          end
        end
        results
      end
    end

    def fake_suggested_opportunities(site, site_elements)
      {
        "high traffic, low conversion" =>  [["co:USA", 100, 1], ["dv:Mobile", 200, 2], ["rf:http://zombo.com", 130, 4]],
        "low traffic, high conversion" =>  [["co:Russia", 10, 9], ["dv:Desktop", 22, 20], ["pu:http://zombo.com/signup", 5, 4]],
        "high traffic, high conversion" => [["co:China", 100, 30], ["ad_so:Google AdWords", 200, 55], ["co:Canada", 430, 120]]
      }
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
      Timeout::timeout(5) do
        url = URI.join(Hellobar::Settings[:data_api_url], Hello::DataAPIHelper.url_for(path, params)).to_s
        response = Net::HTTP.get(URI.parse(url))
        JSON.parse(response)
      end
    rescue JSON::ParserError, SocketError
      Rails.logger.error("Data API Error: #{response if defined?(response)}")
      return nil
    rescue Timeout::Error
      Rails.logger.error("Data API Error: Request Timeout")
      return nil
    end
  end
end
