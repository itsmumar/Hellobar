class RuleSetting < ActiveRecord::Base
  serialize :exclude_urls
  serialize :include_urls

  def public_attributes
    as_json(except: [:id, :rule_id, :created_at, :updated_at])
  end
end
