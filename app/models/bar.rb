class Bar < ActiveRecord::Base
  has_many :rules
  has_many :bars, through: :rules

  has_one :bar_setting

  def settings
    bar_setting || BarSetting.new
  end
end
