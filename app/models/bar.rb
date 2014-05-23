class Bar < ActiveRecord::Base
  belongs_to :rule

  has_one :bar_setting

  def settings
    bar_setting || BarSetting.new
  end
end
