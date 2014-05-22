class Bar < ActiveRecord::Base
  include EmbeddableContent

  has_many :rules
  has_many :bars, through: :rules

  has_one :bar_setting

  content_name = 'bar'

  def settings
    bar_setting || BarSetting.new
  end
end
