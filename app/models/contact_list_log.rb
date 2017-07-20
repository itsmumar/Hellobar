class ContactListLog < ActiveRecord::Base
  belongs_to :contact_list

  scope :completed, -> { where(completed: true) }

  def self.statuses(subscribers)
    emails = subscribers.map { |subscriber| subscriber[:email] }
    logs = where(email: emails).inject({}) { |hash, contact| hash.update contact.email => contact.status }

    emails.inject({}) do |hash, email|
      hash.update email => logs.fetch(email, 'Not Synced')
    end
  end

  def status
    completed? ? 'Sent' : 'Error'
  end
end
