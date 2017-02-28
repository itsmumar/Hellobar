class Autofill < ActiveRecord::Base

   belongs_to :site, touch: true

   validates :site, presence: true
   validates :name, presence: true
   validates :listen_selector, presence: true
   validates :populate_selector, presence: true

end
