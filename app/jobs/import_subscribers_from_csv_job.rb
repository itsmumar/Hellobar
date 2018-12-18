class ImportSubscribersFromCsvJob < ApplicationJob
  def perform(csv_upload)
    return unless csv_upload&.contact_list
    ImportSubscribersFromCsv.new(csv_upload.file, csv_upload.contact_list).call
  end
end
