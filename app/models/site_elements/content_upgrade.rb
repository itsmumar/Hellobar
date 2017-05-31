class ContentUpgrade < SiteElement
  has_attached_file :content_upgrade_pdf

  validates_attachment :content_upgrade_pdf, presence: true, content_type: { content_type: 'application/pdf' }

  def content_upgrade_download_link
    content_upgrade_pdf.url
  end

  def content_upgrade_script_tag
    content = %(window.onload = function() {hellobar("contentUpgrades").show(#{ id });};)
    %(<script id="hb-cu-#{ id }">#{ content }</script>)
  end

  def display_title
    title.present? ? title : offer_headline
  end
end
