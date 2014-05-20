class Bar < ActiveRecord::Base
  has_one :bar_setting

  def settings
    bar_setting || BarSetting.new
  end
end
