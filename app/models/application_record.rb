class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Monkey-patch to always print record ID when doing `#to_s`
  def to_s
    "<#{ self.class }##{ format('0x00%x', (object_id << 1)) } id:#{ id.inspect }>"
  end
end
