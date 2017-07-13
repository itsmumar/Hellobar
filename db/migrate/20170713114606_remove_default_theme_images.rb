class RemoveDefaultThemeImages < ActiveRecord::Migration
  def up
    ImageUpload.where.not(theme_id: nil).destroy_all
  end
end
