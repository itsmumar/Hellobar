class ImportSubscribersFromCsv
  # @param [ActionDispatch::Http::UploadedFile] uploaded_file
  # @param [ContactList] contact_list
  def initialize(uploaded_file, contact_list)
    @csv = CSV.new(uploaded_file.read)
    @contact_list = contact_list
  end

  def call
    csv.each do |email, name|
      create_subscriber email, name if email.present?
    end
  end

  private

  attr_reader :csv, :contact_list

  def create_subscriber(email, name)
    CreateSubscriber.new(contact_list, email: email, name: name).call
  rescue CreateSubscriber::InvalidEmailError => e
    Rails.logger.info e.message
  end
end
