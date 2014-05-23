class Bar < ActiveRecord::Base
  belongs_to :rule

  has_one :bar_setting

  def settings
    bar_setting || BarSetting.new
  end

  def public_attributes
    {
      id: id,
      target: 'db:desktop',
      template_name: goal
    }
  end

  def public_attributes_with_settings
    settings.public_attributes.merge({
      :id => id,
      :target => target_segment,
      :template_name => goal
    })
  end
end
