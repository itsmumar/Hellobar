class Rule < ActiveRecord::Base
  belongs_to :site
  belongs_to :bar

  has_one :rule_setting

  def settings
    rule_setting || RuleSetting.new
  end
end
