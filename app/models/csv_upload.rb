class CsvUpload < ApplicationRecord
  belongs_to :contact_list

  has_attached_file :csv
  validates_attachment_content_type :csv, content_type: /\Atext\/(csv|plain)\Z/

  def file
    Paperclip.io_adapters.for(csv)
  end
end
