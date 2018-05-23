class ContentUpgradeSettings < ActiveRecord::Base
  belongs_to :content_upgrade

  has_attached_file :content_upgrade_pdf, s3_headers: { 'Content-Disposition' => 'attachment' }

  validates :offer_headline, presence: true
  validates :disclaimer, presence: true
  validates_attachment :content_upgrade_pdf, presence: true, content_type: { content_type: 'application/pdf' }
  validates :thank_you_headline, presence: true, if: :thank_you_enabled?
  validates :thank_you_subheading, presence: true, if: :thank_you_enabled?
  validates :thank_you_cta, presence: true, if: :thank_you_enabled?
  validates :thank_you_url, url: true, if: :thank_you_enabled?

  def content_upgrade_download_link
    content_upgrade_pdf&.url
  end

  def display_title
    content_upgrade_title.presence || offer_headline
  end
end
