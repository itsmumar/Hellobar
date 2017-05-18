class ContentUpgrade < SiteElement
  has_attached_file :content_upgrade_pdf

  validates_attachment :content_upgrade_pdf, presence: true, content_type: { content_type: 'application/pdf' }

  def content_upgrade_key
    "#{ Site.id_to_script_hash(site.id) }/#{ id }.pdf"
  end

  def content_upgrade_download_link
    content_upgrade_pdf.url
  end

  def content_upgrade_script_tag
    '<script id="hb-cu-' + id.to_s + '">window.onload = function() {hellobar("contentUpgrades").show(' + id.to_s + ');};</script>'
  end

  def content_upgrade_wp_shortcode
    '[hellobar_content_upgrade id="' + id.to_s + '"]'
  end
end
