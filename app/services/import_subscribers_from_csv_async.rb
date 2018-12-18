class ImportSubscribersFromCsvAsync
  # @param [ActionDispatch::Http::UploadedFile] uploaded_file
  # @param [ContactList] contact_list
  def initialize(uploaded_file, contact_list)
    @uploaded_file = uploaded_file
    @contact_list = contact_list
  end

  def call
    csv_upload.save!
    ImportSubscribersFromCsvJob.perform_later csv_upload
  end

  private

  attr_reader :uploaded_file, :contact_list

  def csv_upload
    @csv_upload ||= CsvUpload.new(
      csv: uploaded_file,
      contact_list: contact_list
    )
  end
end
