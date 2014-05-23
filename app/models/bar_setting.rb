class BarSetting < ActiveRecord::Base
  belongs_to :bar

  def public_attributes
    as_json(except: [:id, :created_at, :updated_at])
  end
end
