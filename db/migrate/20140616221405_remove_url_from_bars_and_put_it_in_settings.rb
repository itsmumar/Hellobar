class RemoveURLFromBarsAndPutItInSettings < ActiveRecord::Migration
  def change
    remove_column :bars, :url
  end
end
