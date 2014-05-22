class Rule < ActiveRecord::Base
  has_one :rule_setting

  def settings
    rule_setting || RuleSetting.new
  end
end
