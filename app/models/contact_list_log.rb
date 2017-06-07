class ContactListLog < ActiveRecord::Base
  belongs_to :contact_list

  scope :completed, -> { where(completed: true) }

  def self.processed(subscribers)
    emails = subscribers.map { |subscriber| subscriber[:email] }
    select(:email).where(email: emails).completed.pluck(:email)
  end
end
