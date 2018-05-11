class ExportSubscribers
  def initialize(contact_list, sleep_interval = 0)
    @contact_list = contact_list
    @sleep_interval = sleep_interval
  end

  def call
    CSV.generate do |csv|
      csv << %w[Email Fields Subscribed\ At]
      subscribers = FetchSubscribers.new(contact_list, page_size: nil).call
      loop do
        subscribers[:items].each do |subscriber|
          csv << [subscriber.email, subscriber.name, subscriber.subscribed_at.to_s]
        end

        break unless subscribers[:next_page]

        sleep(sleep_interval)

        subscribers = FetchSubscribers.new(contact_list, subscribers[:next_page]).call
      end
    end
  end

  private

  attr_reader :contact_list, :sleep_interval
end
