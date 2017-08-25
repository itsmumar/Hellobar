class TrackHistoricalScriptInstalls < ActiveRecord::Migration
  def change
    Site.where('created_at > ? AND script_installed_at IS NOT NULL', Time.gm(2017, 8, 9)).find_each do |site|
      site.owners.each do |owner|
        TrackEvent.new(:installed_script, site: site, user: owner).call
      end
    end

    Site.script_uninstalled.where('created_at > ?', Time.gm(2017, 8, 9)).find_each do |site|
      site.owners.each do |owner|
        TrackEvent.new(:uninstalled_script, site: site, user: owner).call
      end
    end
  end
end
