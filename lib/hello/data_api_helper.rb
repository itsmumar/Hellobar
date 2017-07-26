# This module provides the methods for generating the path and params
# for various API methods. It does not issue requests, handle errors
# or parse responses as there are plenty of libraries for that

require './lib/obfuscated_id'
require 'hmac-sha1'
require 'hmac-sha2'
require 'cgi'

module Hello
  class DataAPIHelper
    class << self
      def url_for_contacts_csv(list)
        path, params = contacts(list.site_id, list.id, list.site.read_key, nil, nil, 'f' => 'c')
        url_for(path, params)
      end

      protected

      def contacts(site_id, contact_list_id, read_key, limit = nil, start_timestamp = nil, additional_params = {})
        sign_path_and_params(generate_path('e', site_id, contact_list_id), { 'l' => limit.to_i, 'd' => start_timestamp.to_i }.merge(additional_params), read_key)
      end

      # Generates a path for the given site and site element ids
      # Used by other methods
      def generate_path(base_path, site_id, item_ids)
        item_ids = [item_ids] unless item_ids.is_a?(Array)
        "/#{ base_path }/#{ ObfuscatedID.generate(site_id) }/#{ item_ids.collect { |e| ObfuscatedID.generate(e) }.join(',') }"
      end

      def sign_path_and_params(path, params, read_key)
        # Required params
        params['t'] = Time.current.to_i
        params['s'] = generate_signature(read_key, path, params)
        [path, params]
      end

      # Generates a signature for the given key, path and parameters (params
      # should be a hash. Key will be either the read key or the write key
      def generate_signature(key, path, params)
        # NOTE: This is using the unencoded values for the params because
        # we don't want to get different signatures if one library encodes a
        # space as "+" and another as "%20" for example
        sorted_param_pairs = (params.keys - ['s']).sort.collect { |k| "#{ k }=#{ params[k] }" }

        signature = HMAC::SHA512.hexdigest(key, path + '?' + sorted_param_pairs.join('|'))
        signature
      end

      # Convenience method that takes a string path and hash of params
      # and returns a URL-encoded url
      def url_for(path, params)
        if params == {}
          # Just the path
          return path
        end
        url = path + '?'
        first = true
        params.each do |key, value|
          url += '&' unless first
          first = false
          url += key + '=' + CGI.escape(value.to_s)
        end
        url
      end
    end
  end
end
