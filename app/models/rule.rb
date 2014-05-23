class Rule < ActiveRecord::Base
  belongs_to :site

  has_many :bars

  has_one :rule_setting

  def settings
    rule_setting || RuleSetting.new
  end
end
