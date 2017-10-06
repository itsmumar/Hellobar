class RenameURLQueryToURLQueryCondition < ActiveRecord::Migration
  def up
    execute "UPDATE conditions SET segment='UrlQueryCondition' WHERE segment='UrlQuery'"
  end

  def down
    execute "UPDATE conditions SET segment='UrlQuery' WHERE segment='UrlQueryCondition'"
  end
end
