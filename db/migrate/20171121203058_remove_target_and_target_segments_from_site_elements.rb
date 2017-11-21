class RemoveTargetAndTargetSegmentsFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :target_segment, :string, limit: 255
    remove_column :site_elements, :target, :string, limit: 255
  end
end
