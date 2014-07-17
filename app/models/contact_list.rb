class ContactList < ActiveRecord::Base
  belongs_to :site
  belongs_to :identity

  serialize :data
end
