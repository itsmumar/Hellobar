json.ignore_nil!
json.cache! site_element do
  json.extract! site_element,
    :id,

    :answer1,
    :answer1response,
    :answer1caption,
    :answer1link_text,
    :answer2,
    :answer2response,
    :answer2caption,
    :answer2link_text,
    :use_question,
    :question,

    :contact_list_id,

    :custom_html,
    :custom_css,
    :custom_js,

    :use_default_image,
    :image_url,
    :image_small_url,
    :image_medium_url,
    :image_large_url,
    :image_modal_url,
    :image_style,
    :image_opacity,
    :open_in_new_window,
    :phone_number,
    :primary_color,
    :pushes_page_down,
    :remains_at_top,
    :secondary_color,
    :settings,
    :target,
    :blocks,
    :animated,
    :background_color,
    :border_color,
    :button_color,
    :email_placeholder,
    :headline,
    :content,
    :image_placement,
    :link_color,
    :link_style,
    :link_text,
    :name_placeholder,
    :phone_number,
    :placement,
    :show_border,
    :show_branding,
    :size,
    :target,
    :text_color,
    :texture,
    :theme_id,
    :type,
    :view_condition,
    :wiggle_button,
    :wordpress_bar_id,
    :blocks,

    :fonts,

    # alert bar
    :sound,
    :notification_delay,
    :trigger_color,
    :trigger_icon_color

  json.font site_element.font.try(:value)
  json.theme site_element.theme.attributes
  json.google_font site_element.font.try(:google_font)
  json.subtype site_element.short_subtype
  json.hide_destination true
  json.wiggle_wait 0
  json.tab_side 'right'
  json.email_redirect site_element.email_redirect?

  json.thank_you_text SiteElement.sanitize(site_element.display_thank_you_text).gsub(/"/, '&quot;')

  json.template_name "#{ site_element.class.name.downcase }_#{ site_element.element_subtype }"

  json.branding_url "http://www.hellobar.com?sid=#{ site_element.id }"

  json.closable(site_element.is_a?(Bar) || site_element.is_a?(Slider) ? site_element.closable : false)

  json.use_free_email_default_msg site_element.show_default_email_message? && site_element.site.free?

  json.updated_at site_element.updated_at.to_f * 1000

  json.caption site_element.caption unless site_element.use_question?

  statistics = site_element.statistics
  json.views statistics.views
  json.conversions statistics.conversions
  json.conversion_rate statistics.conversion_rate
end
