class Condition < ActiveRecord::Base
  self.inheritance_column = 'segment'

  belongs_to :rule
end
