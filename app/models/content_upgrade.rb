class ContentUpgrade < SiteElement
  AVAILABLE_FONTS = {
    'Arial' => 'Arial,Helvetica,sans-serif',
    'Georgia' => 'Georgia,serif',
    'Impact' => 'Impact, Charcoal, sans-serif',
    'Lato' => 'Lato,sans-serif',
    'Montserrat' => 'Montserrat,sans-serif',
    'Open Sans' => '\'Open Sans\',sans-serif',
    'Oswald' => 'Oswald,sans-serif',
    'PT Sans' => '\'PT Sans\',sans-serif',
    'PT Serif' => '\'PT Serif\',sans-serif',
    'Raleway' => 'Raleway, sans-serif',
    'Roboto' => 'Roboto,sans-serif',
    'Tahoma' => 'Tahoma, Geneva, sans-serif',
    'Times New Roman' => '\'Times New Roman\', Times, serif, -webkit-standard',
    'Verdana' => 'Verdana, Geneva, sans-serif'
  }.freeze

  has_one :content_upgrade_settings
  accepts_nested_attributes_for :content_upgrade_settings

  validates :caption, presence: true
  validates :headline, presence: true
  validates :name_placeholder, presence: true
  validates :email_placeholder, presence: true
  validates :link_text, presence: true

  delegate :name, to: :contact_list, prefix: true, allow_nil: true

  delegate :offer_headline, :disclaimer, :content_upgrade_pdf, :content_upgrade_title, :content_upgrade_url,
    :thank_you_enabled, :thank_you_headline, :thank_you_subheading, :thank_you_cta, :thank_you_url,
    :display_title, :content_upgrade_download_link, to: :content_upgrade_settings, allow_nil: true

  def content_upgrade_script_tag
    content = %(window.onload = function() {hellobar("contentUpgrades").show(#{ id });};)
    %(<script id="hb-cu-#{ id }">#{ content }</script>)
  end
end
