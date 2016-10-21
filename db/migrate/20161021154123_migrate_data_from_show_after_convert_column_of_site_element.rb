# https://crossover.atlassian.net/browse/XOHB-202
# Run `rake site:scripts:regenerate_all_active` to enqueue the SQS job for
# regeneration of all active site scripts after completion of this migration

class MigrateDataFromShowAfterConvertColumnOfSiteElement < ActiveRecord::Migration
  SUCCESS_DURATION = 365

  def self.up
    SiteElement.find_each do |site_element|
      if site_element.show_after_convert
        site_element.settings[:cookie_settings] = { duration: 0, success_duration: 0 }
      else
        site_element.settings[:cookie_settings] = case(site_element.type)
                                                  when "Bar", "Slider"
                                                    { duration: 1 } # 1 day
                                                  when "Modal", "Takeover"
                                                    { duration: 1825 } # 5 years
                                                  end.merge(success_duration: SUCCESS_DURATION)
      end

      # Skip callbacks & script regeneration here.
      site_element.update_column(:settings, site_element.settings)
    end
  end

  def self.down
    SiteElement.find_each do |site_element|
      cookie_settings = site_element.settings[:cookie_settings]
      show_after_convert = (cookie_settings[:duration] < 1 && cookie_settings[:success_duration] < 1)
      site_element.settings.delete(:cookie_settings)

      # Skip callbacks & script regeneration here.
      SiteElement.where(id: site_element.id).update_all({
                                                    show_after_convert: show_after_convert,
                                                    settings: site_element.settings
                                                  })
    end
  end
end
