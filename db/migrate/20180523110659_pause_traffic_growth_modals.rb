class PauseTrafficGrowthModals < ActiveRecord::Migration
  def up
    scope = SiteElement.where(theme_id: 'traffic-growth')
    scope.update_all paused: true, theme_id: 'autodetect'
  end
end
