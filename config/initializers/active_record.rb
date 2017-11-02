# TODO: Move to ApplicationRecord when upgraded to Rails 5
class ActiveRecord::Base
  # Monkey-patch ActiveRecord to always print record ID when doing `#to_s`
  def to_s
    "<#{ self.class }##{ format('0x00%x', (object_id << 1)) } id:#{ id.inspect }>"
  end
end
