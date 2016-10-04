class UpdateStorageStructureOfCollectNamesInSiteElements < ActiveRecord::Migration

  # This is a script to port `collect_names` attribute into `fields_to_collect` array
  def self.up
    SiteElement.find_each do |site_element|
      collect_name = (site_element.settings[:collect_names] == 1)

      id = (0...10).map { ('a'..'z').to_a[rand(6)] }.join
      fields_to_collect = site_element.settings[:fields_to_collect]

      if fields_to_collect.is_a?(Array)
        exists = false
        fields_to_collect.each { |ftc| exists = true if ftc["type"] == "builtin-name" }

        site_element.settings.delete(:collect_names) if exists
      else
        site_element.settings.delete(:collect_names)
        site_element.settings[:fields_to_collect] = [{ id: id, type: "builtin-name",
                                                        is_enabled: collect_name }]
      end

      site_element.save
    end
  end

  # This is a script to revert `fields_to_collect` to `collect_names`.
  # `self.down` can be run when `fields_to_collect` only have `name` realted element only.
  def self.down
    begin
      SiteElement.find_each do |site_element|
        collect_name = site_element.settings[:fields_to_collect][0][:is_enabled]

        site_element.settings[:collect_names] = (collect_name ? 1 : 0)
        site_element.settings.delete(:fields_to_collect)
        site_element.save
      end
    rescue Exception
    end
  end
end
