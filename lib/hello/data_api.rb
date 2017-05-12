require './lib/hello/data_api_helper'
require './lib/hello/api_performance'
require 'thread/pool'

module Hello::DataAPI
  # Include this many different IDs in one Data API request
  API_MAX_SLICE = 4

  class << self
    # Returns total views and conversions for each site_element, by day for n days.
    # For example, if site element with id 123 had a total of 10 views and 3 conversions yesterday,
    # and received 5 more views and 1 more conversion today, the response would look like:
    #
    # lifetime_totals(site, [site_element], 2)
    # => {"123" => [[10, 3], [15, 4]]}
    # legend:
    #   site_element_id => [2 days ago, yesterday, today]}
    # where 2 days ago, yesterday and today is an array:
    #   [views_number, conversions_number]
    #
    def lifetime_totals(site, site_elements, num_days = 1, cache_options = {})
      return fake_lifetime_totals(site, site_elements, num_days) if Settings.fake_data_api

      site_element_ids = site_elements.map(&:id).sort

      cache_key = "hello:data-api:#{ site.id }:#{ site_element_ids.sort.join('-') }:lifetime_totals:#{ num_days }days:#{ site.script_installed_at.to_i }"
      cache_options[:expires_in] = 10.minutes

      api_results = Rails.cache.fetch cache_key, cache_options do
        pool = Thread.pool(4)
        results = {}
        semaphore = Mutex.new

        site_element_ids.each_slice(API_MAX_SLICE) do |ids|
          pool.process do
            path, params = Hello::DataAPIHelper::RequestParts.lifetime_totals(site.id, ids, site.read_key, num_days)
            slice_results = get(path, params)
            semaphore.synchronize do
              results.merge!(slice_results) if slice_results
            end
          end
        end

        pool.shutdown
        results
      end

      Hash[api_results.map { |k, v| [k, Performance.new(v)] }]
    end

    def fake_lifetime_totals(_site, site_elements, num_days = 1)
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
    #      :social =>  [[3, 1], [4, 2]],
    #      :call =>    [[4, 1], [4, 2]]
    #    }
    #
    def lifetime_totals_by_type(site, site_elements, num_days = 30, cache_options = {})
      data = Hello::DataAPI.lifetime_totals(site, site_elements, num_days, cache_options) || {}
      totals = { total: [], email: [], social: [], traffic: [], call: [] }
      elements = site.site_elements.where(id: data.keys)
      ids = {}

      # collect the ids of each subtype
      %i[traffic email social call].each do |key|
        ids[key] = elements.select { |e| e.short_subtype == key.to_s }.map { |e| e.id.to_s }
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
        %i[email traffic social call].each do |key|
          type_data = data.select { |k, _| ids[key].include?(k) }
          totals[key] << type_data.inject([0, 0]) do |sum, data_row|
            day_i_data = data_row[1][i]
            [sum[0] + day_i_data[0], sum[1] + day_i_data[1]]
          end
        end
      end

      # remove any zero-padding values that made it through summation
      totals.each do |key, value|
        totals[key] = Performance.new(value.reject { |v| v == [0, 0] })
      end

      totals
    end

    # Returns the total subscribers for each contact list
    #
    # contact_list_totals(site, site.contact_lists)
    # => {"1" => 141, "2" => 951}
    #
    def contact_list_totals(site, contact_lists, cache_options = {})
      return fake_contact_list_totals(contact_lists) if Settings.fake_data_api
      return {} if contact_lists.empty?
      contact_list_ids = contact_lists.map(&:id).sort

      cache_key = "hello:data-api:#{ site.id }:#{ contact_list_ids.sort.join('-') }:contact_list_totals:#{ site.script_installed_at.to_i }"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        results = {}

        contact_list_ids.each_slice(API_MAX_SLICE) do |ids|
          path, params = Hello::DataAPIHelper::RequestParts.contact_list_totals(site.id, ids, site.read_key)
          slice_results = get(path, params)
          results.merge!(slice_results) if slice_results
        end

        results
      end
    end

    def fake_contact_list_totals(contact_lists)
      {}.tap do |results|
        contact_lists.each { |cl| results[cl.id.to_s] = rand(500) }
      end
    end

    # Return name, email and timestamp of subscribers for a contact list
    #
    # contacts(contact_list)
    # => [["person100@gmail.com", "person name", 1388534400], ["person99@gmail.com", "person name", 1388534399]]
    #
    def contacts(contact_list, limit = nil, from_timestamp = nil, cache_options = {})
      return fake_contacts(contact_list) if Settings.fake_data_api
      cache_key = "hello:data-api:#{ contact_list.site_id }:contact_list-#{ contact_list.id }:from#{ from_timestamp }:limit#{ limit }"
      cache_options[:expires_in] = 10.minutes

      Rails.cache.fetch cache_key, cache_options do
        path, params = Hello::DataAPIHelper::RequestParts.contacts(contact_list.site_id, contact_list.id, contact_list.site.read_key, limit, from_timestamp)
        get(path, params)
      end
    end

    def fake_contacts(_contact_list)
      [['dmitriy+person100@polymathic.me', 'First Last', 1_388_534_400], ['dmitriy+person99@polymathic.me', 'Dr Pepper', 1_388_534_399]]
    end

    def get(path, params)
      timeouts = [3, 3, 5, 5, 8] # Determines the length and number of attempts
      timeout_index = 0
      begin
        begin_time = Time.current.to_f
        url = URI.join(Settings.data_api_url, Hello::DataAPIHelper.url_for(path, params)).to_s
        response = nil
        Timeout.timeout(timeouts[timeout_index]) do
          response = Net::HTTP.get(URI.parse(url))
        end
        results = JSON.parse(response)
        return results
      rescue Timeout::Error => _
        # If it's just a timeout, keep retrying while we can
        timeout_index += 1
        retry if timeouts[timeout_index]
        # Ran out of attempts, re-raise the error
        raise
      end
    rescue StandardError => e
      now = Time.current
      duration = now.to_f - begin_time
      # Log the error
      lines = ["[#{ now }] Data API Error::#{ e.class } (#{ duration }s) - #{ e.message.inspect } => #{ url.inspect }"]
      lines << "Response: #{ response.inspect }" if response
      caller[0..4].each do |line|
        lines << "\t#{ line }"
      end
      # Write everything to the log
      File.open(Rails.root.join('log', 'data_api_error.log'), 'a') do |file|
        file.puts(lines.join("\n"))
      end
      # Re-raise the error
      raise
    end
  end
end
