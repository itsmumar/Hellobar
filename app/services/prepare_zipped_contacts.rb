class PrepareZippedContacts
  def initialize(contact_list, filename)
    @contact_list = contact_list
    @filename = filename
  end

  def call
    csv_content = FetchContactsCSV.new(contact_list).call
    zip(csv_content)
  end

  private

  attr_reader :contact_list, :filename

  def zip(csv_content)
    zip_to_buffer(csv_content).string
  end

  def zip_to_buffer(csv_content)
    Zip::OutputStream.write_buffer do |stream|
      stream.put_next_entry filename
      stream.write csv_content
    end
  end
end
