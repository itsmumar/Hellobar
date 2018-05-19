class ContentUpgradeStyles < ActiveRecord::Base
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

  DEFAULT_STYLES = {
    'offer_bg_color' => '#ffffb6',
    'offer_text_color' => '#000000',
    'offer_link_color' => '#1285dd',
    'offer_border_color' => '#000000',
    'offer_border_width' => '0px',
    'offer_border_style' => 'solid',
    'offer_border_radius' => '0px',
    'modal_button_color' => '#1285dd',
    'offer_font_size' => '15px',
    'offer_font_weight' => 'bold',
    'offer_font_family_name' => 'Open Sans'
  }.freeze

  STYLE_ATTRIBUTES = (DEFAULT_STYLES.keys + ['offer_font_family']).freeze

  belongs_to :site

  validates :offer_font_family_name, inclusion: { in: AVAILABLE_FONTS.keys }

  def offer_font_family
    AVAILABLE_FONTS[offer_font_family_name]
  end

  def style_attributes
    STYLE_ATTRIBUTES.each_with_object({}) do |attribute, memo|
      memo[attribute] = public_send(attribute)
    end
  end
end
