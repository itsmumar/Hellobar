class ImproveSuggestion < ActiveRecord::Base
  belongs_to :site
  serialize :data, JSON
  MIN_UPDATE_TIME = 1.hour # Don't update more frequently than this

  class << self
    # Returns the suggestions if it exists
    def get(site, name)
      suggestion = ImproveSuggestion.find_by(site: site, name: name)
      return suggestion ? suggestion.data : nil
    end

    # Returns all the suggestion data in a single query as a hash
    # where the key is the name and the value is the data. 
    # Note: some keys might be missing
    def get_all(site, clear_cache=false)
      results = {}
      site.improve_suggestions(clear_cache).each do |suggestion|
        results[suggestion.name] = suggestion.data
      end
      return results
    end

    # Creates or finds and updates the improve suggestion for the
    # given name
    def generate(site, name, site_elements)
      name = name.to_s
      suggestion = ImproveSuggestion.find_or_initialize_by(site: site, name: name)

      # Make sure we don't update something that was recently updated
      if suggestion.updated_at and Time.now-suggestion.updated_at < MIN_UPDATE_TIME
        return false
      end

      site_element_ids = site_elements.map(&:id).sort
      path, params = Hello::DataAPIHelper::RequestParts.suggested_opportunities(site.id, site_element_ids, site.read_key)
      suggestion.data = Hello::DataAPI.get(path, params)
      suggestion.save!
      suggestion
    end

    # Returns a hash the key is the "name" of the improve suggestion group
    # and the value is an array of site elements. Can be used by generate_all
    # to update all improve suggestions for a group
    def determine_groups(site)
      groups = {}
      groups["all"] = site.site_elements
      # Subtypes
      SiteElement::SHORT_SUBTYPES.each do |type|
        groups[type] = site.site_elements.reject{|s| s.short_subtype != type}
      end
      return groups
    end

    # Generates all the updates for the given site
    def generate_all(site)
      results = {}
      determine_groups(site).each do |name, site_elements|
        results[name] = generate(site, name, site_elements)
      end

      return results
    end

  end
end
