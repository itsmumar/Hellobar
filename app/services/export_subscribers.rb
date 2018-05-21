class ExportSubscribers
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    CSV.generate do |csv|
      csv << %w[Email Fields Subscribed\ At]
      subscribers = FetchSubscribers.new(contact_list).call
      loop do
        subscribers[:items].each do |subscriber|
          csv << [subscriber.email, subscriber.name, subscriber.subscribed_at.to_s]
        end

        break unless subscribers[:next_page]

        subscribers = FetchSubscribers.new(contact_list, subscribers[:next_page]).call
      end
    end
  end

  private

  attr_reader :contact_list
end
