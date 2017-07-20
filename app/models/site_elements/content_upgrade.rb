class ContentUpgrade < SiteElement
  has_attached_file :content_upgrade_pdf, s3_headers: { 'Content-Disposition' => 'attachment' }

  validates_attachment :content_upgrade_pdf, presence: true, content_type: { content_type: 'application/pdf' }
  validates :offer_headline, presence: true
  validates :caption, presence: true
  validates :headline, presence: true
  validates :name_placeholder, presence: true
  validates :email_placeholder, presence: true
  validates :link_text, presence: true
  validates :disclaimer, presence: true

  # thank you content
  validates :thank_you_headline, presence: true, if: :thank_you_enabled?
  validates :thank_you_subheading, presence: true, if: :thank_you_enabled?
  validates :thank_you_cta, presence: true, if: :thank_you_enabled?
  validates :thank_you_url, url: true, if: :thank_you_enabled?

  def content_upgrade_download_link
    content_upgrade_pdf.url
  end

  def content_upgrade_script_tag
    content = %(window.onload = function() {hellobar("contentUpgrades").show(#{ id });};)
    %(<script id="hb-cu-#{ id }">#{ content }</script>)
  end

  def display_title
    content_upgrade_title.present? ? content_upgrade_title : offer_headline
  end
end
